package app.animestream

import eu.kanade.tachiyomi.animesource.AnimeCatalogueSource
import eu.kanade.tachiyomi.animesource.AnimeSource
import eu.kanade.tachiyomi.animesource.model.*
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import java.util.concurrent.TimeUnit

/**
 * Version-neutral calls: modern suspend API first, legacy RxJava as fallback.
 * Only fallback for genuinely unsupported methods, not for HTTP/parser failures.
 */
internal object ExtensionSourceCalls {
    private const val WAIT_MS = 35000L

    private fun unsupported(error: Throwable): Boolean {
        val cause = (error as? java.lang.reflect.InvocationTargetException)?.targetException ?: error
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
            // An empty hoster list is meaningful and must not use a different API.
            for (hoster in hosters.take(30)) {
                val predefined = hoster.videoList
                if (predefined != null) {
                    collected.addAll(predefined)
                } else {
                    collected.addAll(runBlocking {
                        withTimeout(WAIT_MS) { source.getVideoList(hoster) }
                    })
                }
            }
            return collected.distinctBy { it.videoUrl to it.videoTitle }
        }

        // Extensions-lib 1.5+ direct coroutine API.
        return try {
            runBlocking { withTimeout(WAIT_MS) { source.getVideoList(episode) } }
        } catch (e: Throwable) {
            if (!unsupported(e)) throw e
            // Legacy extensions-lib RxJava API.
            source.fetchVideoList(episode).toBlocking()
                .toFuture().get(WAIT_MS, TimeUnit.MILLISECONDS)
        }
    }
}
