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
    /** Validate URL shapes without returning or logging potentially signed links. */
    private fun isPlayableHttpUrl(value: String): Boolean {
        val uri = try { android.net.Uri.parse(value.trim()) } catch (_: Exception) { null }
        return uri != null &&
            uri.scheme?.lowercase() in setOf("http", "https") &&
            !uri.host.isNullOrBlank()
    }

    /**
     * Check for an extension-provided legacy resolver before issuing another
     * HTTP request. AnimeHttpSource has a default fetchVideoUrl, and the
     * shared ParsedAnimeHttpSource has a default HTML parser: neither proves
     * that the installed extension can actually resolve a video page.
     */
    private fun supportsLegacyVideoUrl(source: AnimeHttpSource): Boolean {
        var type: Class<*>? = source.javaClass
        while (type != null && type != AnimeHttpSource::class.java) {
            if (type != eu.kanade.tachiyomi.animesource.online.ParsedAnimeHttpSource::class.java &&
                type.declaredMethods.any { method ->
                    val parameters = method.parameterTypes
                    when (method.name) {
                        "getVideoUrl" ->
                            parameters.size == 2 && parameters[0] == Video::class.java
                        "fetchVideoUrl" ->
                            parameters.size == 1 && parameters[0] == Video::class.java
                        "videoUrlParse" ->
                            parameters.size == 1 &&
                            (parameters[0] == okhttp3.Response::class.java ||
                                parameters[0] == org.jsoup.nodes.Document::class.java)
                        else -> false
                    }
                }) return true
            type = type.superclass
        }
        return false
    }

    /**
     * Different extensions resolve lazy links in different ways:
     * 1) extensions-lib 1.6: resolveVideo(Video) -> Video?
     * 2) legacy extensions: getVideoUrl(Video) -> String using videoPageUrl
     *
     * Neither path should touch a video that already supplies a playable URL.
     * If the legacy resolver succeeds, copy rather than reconstructing Video so
     * subtitle/audio tracks, headers, title and quality metadata are retained.
     */
    private fun resolveLazyVideos(source: AnimeSource, videos: List<Video>): List<Video> {
        val httpSource = source as? AnimeHttpSource ?: return videos
        val hasLegacyResolver = supportsLegacyVideoUrl(httpSource)
        return videos.map { original ->
            if (isPlayableHttpUrl(original.videoUrl)) return@map original

            val modern = try {
                runBlocking {
                    withTimeout(WAIT_MS) { httpSource.resolveVideo(original) }
                } ?: original
            } catch (_: Throwable) {
                original
            }

            if (isPlayableHttpUrl(modern.videoUrl) ||
                !hasLegacyResolver || !isPlayableHttpUrl(modern.videoPageUrl)) {
                return@map modern
            }

            val resolvedUrl = try {
                runBlocking {
                    withTimeout(WAIT_MS) { httpSource.getVideoUrl(modern) }
                }
            } catch (_: Throwable) {
                null
            }

            if (resolvedUrl != null && isPlayableHttpUrl(resolvedUrl)) {
                modern.copy(videoUrl = resolvedUrl.trim())
            } else {
                modern
            }
        }.distinctBy { it.videoUrl to it.videoTitle }
    }

}
