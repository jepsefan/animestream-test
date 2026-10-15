package app.animestream

import eu.kanade.tachiyomi.animesource.AnimeCatalogueSource
import eu.kanade.tachiyomi.animesource.AnimeSource
import eu.kanade.tachiyomi.animesource.model.*
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import java.util.concurrent.TimeUnit
import java.util.concurrent.ExecutionException
import eu.kanade.tachiyomi.animesource.online.AnimeHttpSource

/**
 * Version-neutral calls: modern suspend API first, legacy RxJava as fallback.
 * Only fallback for genuinely unsupported methods, not for HTTP/parser failures.
 */
internal object ExtensionSourceCalls {
    private const val WAIT_MS = 35000L

    private fun unsupported(error: Throwable): Boolean {
        val cause = when (error) {
            is java.lang.reflect.InvocationTargetException -> error.targetException ?: error
            is ExecutionException -> error.cause ?: error
            else -> error
        }
        return cause is AbstractMethodError || cause is NoSuchMethodError ||
            cause is UnsupportedOperationException ||
            cause is java.lang.IncompatibleClassChangeError ||
            (cause is IllegalStateException && cause.message == "Not used")
    }

    fun search(source: AnimeCatalogueSource, query: String): AnimesPage {
        val filters = source.getFilterList()
        return try {
            runBlocking { withTimeout(WAIT_MS) { source.getSearchAnime(1, query, filters) } }
        } catch (e: Throwable) {
            if (!unsupported(e)) throw e
            source.fetchSearchAnime(1, query, filters).toBlocking()
                .toFuture().get(WAIT_MS, TimeUnit.MILLISECONDS)
        }
    }

    fun episodes(source: AnimeSource, anime: SAnime): List<SEpisode> {
        return try {
            runBlocking { withTimeout(WAIT_MS) { source.getEpisodeList(anime) } }
        } catch (e: Throwable) {
            if (!unsupported(e)) throw e
            source.fetchEpisodeList(anime).toBlocking()
                .toFuture().get(WAIT_MS, TimeUnit.MILLISECONDS)
        }
    }

    fun videos(source: AnimeSource, episode: SEpisode): List<Video> {
        // Extensions-lib 1.6+: obtain available hosters, then resolve each.
        val hosters: List<Hoster>? = try {
            runBlocking { withTimeout(WAIT_MS) { source.getHosterList(episode) } }
        } catch (e: Throwable) {
            if (!unsupported(e)) throw e
            null
        }
        if (hosters != null) {
            val collected = mutableListOf<Video>()
            var lastFailure: Throwable? = null
            // A single unavailable hoster must not hide working alternatives.
            for (hoster in hosters.take(30)) {
                try {
                    val offered = hoster.videoList ?: runBlocking {
                        withTimeout(WAIT_MS) { source.getVideoList(hoster) }
                    }
                    collected.addAll(offered)
                } catch (failure: Throwable) {
                    lastFailure = failure
                }
            }
            if (collected.isEmpty() && lastFailure != null) throw lastFailure
            return resolveLazyVideos(source, collected)
        }

        // Extensions-lib 1.5+ direct coroutine API.
        val direct = try {
            runBlocking { withTimeout(WAIT_MS) { source.getVideoList(episode) } }
        } catch (e: Throwable) {
            if (!unsupported(e)) throw e
            source.fetchVideoList(episode).toBlocking()
                .toFuture().get(WAIT_MS, TimeUnit.MILLISECONDS)
        }
        return resolveLazyVideos(source, direct)
    }
    private fun resolveLazyVideos(source: AnimeSource, videos: List<Video>): List<Video> {
        val httpSource = source as? AnimeHttpSource ?: return videos
        return videos.mapNotNull { video ->
            // Already-playable streams must never be re-fetched. Some legacy
            // extractors return "null" as a placeholder for unresolved URLs.
            val candidate = video.videoUrl.trim()
            if (candidate.startsWith("http://", true) ||
                candidate.startsWith("https://", true)) return@mapNotNull video
            try {
                runBlocking { withTimeout(WAIT_MS) { httpSource.resolveVideo(video) } }
                    ?: video
            } catch (_: Throwable) {
                // Do not discard original candidates; diagnostics can still
                // report that the hoster returned no playable stream.
                video
            }
        }.distinctBy { it.videoUrl to it.videoTitle }
    }

}
