package app.animestream

import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import dalvik.system.DexFile
import eu.kanade.tachiyomi.animesource.AnimeSource
import eu.kanade.tachiyomi.animesource.model.SAnime
import eu.kanade.tachiyomi.animesource.online.AnimeHttpSource
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import eu.kanade.tachiyomi.network.NetworkHelper
import java.io.File
import java.util.concurrent.TimeUnit
import kotlinx.serialization.json.Json
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.TypeReference

/**
 * One explicitly selected source result, no background discovery, episode streams
 * or playback. This does NOT guess an episode list from an AniList entry.
 */
internal class ExtensionEpisodeProbe(private val context: Context) {
    fun load(
        packageName: String, sourceUrl: String, sourceTitle: String,
        sourceId: Long? = null, approvedName: String? = null,
        approvedLanguage: String? = null
    ): Map<String, Any?> {
        if (sourceUrl.isBlank() || sourceTitle.isBlank()) {
            return mapOf("status" to "invalid_selection")
        }
        return try {
            perform(packageName, sourceUrl, sourceTitle, sourceId,
                approvedName, approvedLanguage)
        } catch (error: Throwable) {
            val errors = mutableListOf<String>()
            val seen = java.util.Collections.newSetFromMap(
                java.util.IdentityHashMap<Throwable, Boolean>()
            )
            var throwable: Throwable? = error
            while (throwable != null && seen.add(throwable) && errors.size < 8) {
                errors.add(throwable.javaClass.simpleName + ": " + (throwable.message ?: ""))
                throwable = if (throwable is java.lang.reflect.InvocationTargetException) {
                    throwable.targetException ?: throwable.cause
                } else throwable.cause
            }
            mapOf(
                "status" to "episode_list_failed",
                "error" to errors.joinToString(" -> "),
                "stackTrace" to error.stackTraceToString().take(8000)
            )
        }
    }

    /** Resolve extension-provided episode artwork without making network requests.
     * Supports absolute, protocol-relative and relative preview URLs. Invalid
     * schemes are ignored; missing previews remain empty for Flutter fallback.
     */
    private fun episodePreviewUrl(preview: String?, baseUrl: HttpUrl?): String {
        val raw = preview?.trim()?.takeIf { it.isNotEmpty() && it.length <= 4096 }
            ?: return ""
        return (raw.toHttpUrlOrNull() ?: baseUrl?.resolve(raw))
            ?.toString().orEmpty()
    }

    private fun perform(
        packageName: String, sourceUrl: String, sourceTitle: String,
        sourceId: Long?, approvedName: String?, approvedLanguage: String?
    ): Map<String, Any?> {
        val app = context.applicationContext as? Application
            ?: return mapOf("status" to "missing_application")
        val helper = NetworkHelper.initialize(app)
        helper.beginSearchDiagnostics("")
        synchronized(ExtensionEpisodeProbe::class.java) {
            Injekt.addSingleton(object : TypeReference<Application> {
                override val type: java.lang.reflect.Type = Application::class.java
            }, app)
            Injekt.addSingleton(object : TypeReference<NetworkHelper> {
                override val type: java.lang.reflect.Type = NetworkHelper::class.java
            }, helper)
            Injekt.addSingleton(object : TypeReference<Json> {
                override val type: java.lang.reflect.Type = Json::class.java
            }, Json { ignoreUnknownKeys = true; explicitNulls = false })
        }
        val source = ExtensionHostRuntime(context).load(
            packageName, sourceId, approvedName, approvedLanguage
        ).source
        val anime = SAnime.create().apply {
            url = sourceUrl
            title = sourceTitle
        }
        val episodes = ExtensionSourceCalls.episodes(source, anime)
        // Prefer the current extension domain; a fallback to an absolute
        // selected series URL also works for non-HTTP catalogue sources.
        val artworkBase = (source as? AnimeHttpSource)?.baseUrl?.toHttpUrlOrNull()
            ?: sourceUrl.toHttpUrlOrNull()
        return mapOf(
            "status" to "episode_list_completed",
            "sourceTitle" to sourceTitle,
            "episodeCount" to episodes.size,
            "episodes" to episodes.take(100).map {
                mapOf(
                    "name" to it.name,
                    "url" to it.url,
                    "number" to it.episode_number,
                    "preview" to episodePreviewUrl(it.preview_url, artworkBase)
                )
            },
            "truncated" to (episodes.size > 100),
            "networkDiagnostics" to helper.searchNetworkDiagnostics()
        )
    }
    fun loadStreams(
        packageName: String, episodeUrl: String, episodeName: String,
        sourceId: Long? = null, approvedName: String? = null,
        approvedLanguage: String? = null
    ): Map<String, Any?> {
        if (episodeUrl.isBlank() || episodeName.isBlank()) {
            return mapOf("status" to "invalid_episode_selection")
        }
        return try {
            performStreams(packageName, episodeUrl, episodeName,
                sourceId = sourceId, approvedName = approvedName,
                approvedLanguage = approvedLanguage)
        } catch (error: Throwable) {
            val result = ExtensionLinkageDiagnostics.describe(error).toMutableMap()
            val failedHost = NetworkHelper.requireInstance().streamFailureHost()
            if (!failedHost.isNullOrBlank()) result["failedDnsHost"] = failedHost
            result
        }
    }

    /**
     * Only called for an explicitly selected playback source. Unlike the
     * diagnostic method this returns live URLs/headers to the player bridge.
     * Never include those values in diagnostic output or log messages.
     */
    fun resolvePlaybackStreams(
        packageName: String, episodeUrl: String, episodeName: String,
        sourceId: Long? = null, approvedName: String? = null,
        approvedLanguage: String? = null
    ): Map<String, Any?> {
        if (episodeUrl.isBlank() || episodeName.isBlank()) {
            return mapOf("status" to "invalid_episode_selection")
        }
        return try {
            performStreams(packageName, episodeUrl, episodeName,
                sourceId = sourceId, forPlayback = true,
                approvedName = approvedName, approvedLanguage = approvedLanguage)
        } catch (error: Throwable) {
            ExtensionLinkageDiagnostics.describe(error)
        }
    }

    private fun performStreams(
        packageName: String, episodeUrl: String, episodeName: String,
        sourceId: Long? = null, forPlayback: Boolean = false,
        approvedName: String? = null, approvedLanguage: String? = null
    ): Map<String, Any?> {
        val app = context.applicationContext as? Application
            ?: return mapOf("status" to "missing_application")
        val helper = NetworkHelper.initialize(app)
        helper.beginSearchDiagnostics("")
        synchronized(ExtensionEpisodeProbe::class.java) {
            Injekt.addSingleton(object : TypeReference<Application> {
                override val type: java.lang.reflect.Type = Application::class.java
            }, app)
            Injekt.addSingleton(object : TypeReference<NetworkHelper> {
                override val type: java.lang.reflect.Type = NetworkHelper::class.java
            }, helper)
            Injekt.addSingleton(object : TypeReference<Json> {
                override val type: java.lang.reflect.Type = Json::class.java
            }, Json { ignoreUnknownKeys = true; explicitNulls = false })
        }
        val source = try {
            ExtensionHostRuntime(context).load(
                packageName, sourceId, approvedName, approvedLanguage
            ).source
        } catch (failure: Throwable) {
            throw ExtensionStreamStageFailure("load_source", failure)
        }
        val episode = eu.kanade.tachiyomi.animesource.model.SEpisode.create().apply {
            url = episodeUrl
            name = episodeName
        }
        // One opt-in test. Observe cache hits as well as network requests.
        helper.beginStreamDiagnostics()
        val videos = try {
            try {
                ExtensionSourceCalls.videos(source, episode)
            } catch (failure: Throwable) {
                throw ExtensionStreamStageFailure("resolve_videos", failure)
            }
        } finally {
            helper.endStreamDiagnostics()
        }
        if (forPlayback) {
            val playable = videos.take(40).mapNotNull { candidate ->
                val video = candidate.video
                val url = video.videoUrl
                val uri = try { android.net.Uri.parse(url) } catch (_: Exception) { null }
                if (uri == null || uri.scheme?.lowercase() !in setOf("http", "https") ||
                    uri.host.isNullOrBlank()) return@mapNotNull null
                // Keep every external track and its language/format. These are
                // playback-only values: never add URLs to diagnostic summaries.
                val subtitles = video.subtitleTracks.mapNotNull { track ->
                    val raw = track.url.trim()
                    val address = try { android.net.Uri.parse(raw) } catch (_: Exception) { null }
                    if (address == null ||
                        address.scheme?.lowercase() !in setOf("http", "https") ||
                        address.host.isNullOrBlank()) return@mapNotNull null
                    val path = address.path?.lowercase() ?: ""
                    val language = track.lang.trim().ifBlank { "Unknown" }
                    val hint = language.lowercase()
                    val format = when {
                        path.endsWith(".ass") || path.endsWith(".ssa") ||
                            hint.contains(".ass") || hint.contains("[ass]") ||
                            hint.contains("[ssa]") || hint.contains("(ass)") ||
                            hint.contains("(ssa)") -> "ass"
                        path.endsWith(".vtt") || hint.contains("[vtt]") ||
                            hint.contains("(vtt)") -> "vtt"
                        path.endsWith(".srt") || hint.contains("[srt]") ||
                            hint.contains("(srt)") -> "srt"
                        else -> ""
                    }
                    mapOf(
                        "url" to raw,
                        "language" to language,
                        "format" to format,
                        "label" to language
                    )
                }
                // External audio is metadata for now; audio-only URLs cannot
                // be attached to an unrelated video using BetterPlayer's HLS
                // audio selector. Keep all supported tracks for a future
                // platform-specific audio mixer and display their languages.
                val audioTracks = video.audioTracks.take(24).mapNotNull { track ->
                    val raw = track.url.trim()
                    val address = try { android.net.Uri.parse(raw) } catch (_: Exception) { null }
                    if (address == null ||
                        address.scheme?.lowercase() !in setOf("http", "https") ||
                        address.host.isNullOrBlank()) return@mapNotNull null
                    val language = track.lang.trim().ifBlank { "Unknown" }
                    mapOf(
                        "url" to raw,
                        "language" to language,
                        "label" to language
                    )
                }
                val initialSubtitle = subtitles.firstOrNull()
                mapOf(
                    "url" to url,
                    "quality" to video.videoTitle.ifBlank { "Auto" },
                    "server" to packageName.substringAfterLast('.'),
                    "hosterName" to (candidate.hosterName ?: ""),
                    "headers" to (video.headers?.toMultimap()?.mapValues {
                        it.value.joinToString("; ")
                    } ?: emptyMap<String, String>()),
                    "subtitle" to (initialSubtitle?.get("url") ?: ""),
                    "subtitleFormat" to (initialSubtitle?.get("format") ?: ""),
                    "subtitleTracks" to subtitles,
                    "audioTracks" to audioTracks,
                    "audioTrackCount" to video.audioTracks.size,
                    "subtitleTrackCount" to video.subtitleTracks.size
                )
            }
            return mapOf(
                "status" to if (playable.isEmpty()) "stream_list_empty" else "stream_list_completed",
                "videos" to playable,
                "videoCount" to playable.size,
                "diagnosis" to if (playable.isEmpty()) "extension_returned_no_playable_http_stream"
                    else "streams_returned",
                "safeRequestSummary" to if (playable.isEmpty())
                    summarizeStreamRequests(helper.streamRequestDiagnostics()) else emptyList()
            )
        }
        val traces = summarizeStreamRequests(helper.streamRequestDiagnostics())
        val diagnosis = if (videos.isEmpty()) diagnoseEmptyStreamList(packageName, traces)
            else "streams_returned"
        return mapOf(
            "status" to (if (videos.isEmpty()) "stream_list_empty" else "stream_list_completed"),
            "diagnosis" to diagnosis,
            "safeRequestSummary" to traces,
            "episodeName" to episodeName,
            "videoCount" to videos.size,
            "videos" to videos.take(40).map { candidate ->
                val video = candidate.video
                val resolvedUrl = video.videoUrl
                val scheme = try { android.net.Uri.parse(resolvedUrl).scheme.orEmpty() }
                    catch (_: Exception) { "" }
                val host = try { android.net.Uri.parse(resolvedUrl).host.orEmpty() }
                    catch (_: Exception) { "" }
                val format = when {
                    resolvedUrl.contains(".m3u8", true) -> "HLS"
                    resolvedUrl.contains(".mpd", true) -> "DASH"
                    resolvedUrl.contains(".mp4", true) -> "MP4"
                    scheme == "http" && host in listOf("127.0.0.1", "localhost") -> "local_proxy"
                    else -> "unknown"
                }
                mapOf(
                    "quality" to video.videoTitle,
                    "hosterName" to (candidate.hosterName ?: ""),
                    "format" to format,
                    "host" to host,
                    "protocol" to scheme,
                    "resolution" to video.resolution,
                    "bitrate" to video.bitrate,
                    "subtitleCount" to video.subtitleTracks.size,
                    "audioCount" to video.audioTracks.size,
                    "headerNames" to (video.headers?.names()?.filterNot {
                        it.equals("Authorization", ignoreCase = true) ||
                            it.equals("Cookie", ignoreCase = true)
                    }?.take(8) ?: emptyList<String>())
                )
            },
            "truncated" to (videos.size > 40),
            "networkDiagnostics" to emptyList<Map<String, Any?>>()
        )
    }

    /**
     * Stream paths can embed authentication tokens; never send those paths,
     * full URLs, query strings, cookies or headers to the Flutter UI.
     * Classify only known safe endpoint shapes.
     */
    private fun summarizeStreamRequests(
        raw: List<Map<String, Any?>>
    ): List<Map<String, Any?>> = raw.takeLast(35).map { trace ->
        // NetworkHelper has already converted URL paths and response metadata
        // to safe, nonidentifying values.
        mapOf(
            "stage" to trace["stage"],
            "host" to trace["host"],
            "status" to trace["status"],
            "fromCache" to trace["fromCache"],
            "contentType" to trace["contentType"],
            "jsonObject" to trace["jsonObject"],
            "serverTabCount" to trace["serverTabCount"],
            "targetPresent" to trace["targetPresent"],
            "targetIsHttp" to trace["targetIsHttp"],
            "targetShape" to trace["targetShape"],
            "grabberPresent" to trace["grabberPresent"],
            "typePresent" to trace["typePresent"]
        ).filterValues { it != null }
    }

    private fun diagnoseEmptyStreamList(
        packageName: String,
        entries: List<Map<String, Any?>>
    ): String {
        if (entries.isEmpty()) return "no_requests_observed"
        val is123Anime = packageName ==
            "eu.kanade.tachiyomi.animeextension.en.onetwothreeanime"
        val failures = entries.any {
            val status = (it["status"] as? String)?.toIntOrNull()
            status != null && status >= 400
        }
        if (failures) return "upstream_http_error"
        if (!is123Anime) return "extension_returned_no_video"
        val stages = entries.mapNotNull { it["stage"] as? String }.toSet()
        return when {
            "server_tabs" in stages && "episode_server_info" !in stages ->
                "server_tabs_available_but_no_server_info_requests"
            "episode_server_info" in stages &&
                "player_page" !in stages && "alternate_player_page" !in stages ->
                "no_embedded_player_requests"
            "player_page" in stages || "alternate_player_page" in stages ->
                "player_contacted_but_no_usable_playlist_returned"
            else -> "extractor_returned_no_video"
        }
    }

}
