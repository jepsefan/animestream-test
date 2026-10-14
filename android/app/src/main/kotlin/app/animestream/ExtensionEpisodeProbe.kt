package app.animestream

import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import dalvik.system.DexFile
import eu.kanade.tachiyomi.animesource.AnimeSource
import eu.kanade.tachiyomi.animesource.model.SAnime
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
    fun load(packageName: String, sourceUrl: String, sourceTitle: String): Map<String, Any?> {
        if (sourceUrl.isBlank() || sourceTitle.isBlank()) {
            return mapOf("status" to "invalid_selection")
        }
        return try {
            perform(packageName, sourceUrl, sourceTitle)
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

    private fun perform(packageName: String, sourceUrl: String, sourceTitle: String): Map<String, Any?> {
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
        val pm = context.packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getApplicationInfo(packageName,
                PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        }
        val sourceName = info.metaData?.getString("tachiyomi.animeextension.class")
            ?: return mapOf("status" to "no_source_class")
        val entry = sourceName.split(';', ',').first().trim().let {
            if (it.startsWith(".")) packageName + it else it
        }
        val paths = listOfNotNull(info.sourceDir) + (info.splitSourceDirs?.toList() ?: emptyList())
        val extensionClasses = paths.flatMap { apk ->
            val dex = DexFile(apk)
            try {
                val names = mutableListOf<String>()
                val enumeration = dex.entries()
                while (enumeration.hasMoreElements()) names.add(enumeration.nextElement())
                names
            } finally { dex.close() }
        }.toSet()
        val loader = ExtensionIsolatedClassLoader(
            paths.joinToString(File.pathSeparator),
            context.codeCacheDir.absolutePath,
            info.nativeLibraryDir, context.javaClass.classLoader, extensionClasses
        )
        val instance = Class.forName(entry, true, loader).getDeclaredConstructor().newInstance()
        val source = instance as? AnimeSource
            ?: return mapOf("status" to "not_anime_source")
        val anime = SAnime.create().apply {
            url = sourceUrl
            title = sourceTitle
        }
        val episodes = source.fetchEpisodeList(anime).toBlocking().toFuture()
            .get(25, TimeUnit.SECONDS)
        return mapOf(
            "status" to "episode_list_completed",
            "sourceTitle" to sourceTitle,
            "episodeCount" to episodes.size,
            "episodes" to episodes.take(100).map {
                mapOf(
                    "name" to it.name,
                    "url" to it.url,
                    "number" to it.episode_number,
                    "preview" to (it.preview_url ?: "")
                )
            },
            "truncated" to (episodes.size > 100),
            "networkDiagnostics" to helper.searchNetworkDiagnostics()
        )
    }
    fun loadStreams(
        packageName: String, episodeUrl: String, episodeName: String
    ): Map<String, Any?> {
        if (episodeUrl.isBlank() || episodeName.isBlank()) {
            return mapOf("status" to "invalid_episode_selection")
        }
        return try {
            performStreams(packageName, episodeUrl, episodeName)
        } catch (error: Throwable) {
            val errors = mutableListOf<String>()
            val seen = java.util.Collections.newSetFromMap(
                java.util.IdentityHashMap<Throwable, Boolean>()
            )
            var throwable: Throwable? = error
            while (throwable != null && seen.add(throwable) && errors.size < 8) {
                // Messages from extractors can contain signed media URLs.
                errors.add(throwable.javaClass.simpleName)
                throwable = if (throwable is java.lang.reflect.InvocationTargetException) {
                    throwable.targetException ?: throwable.cause
                } else throwable.cause
            }
            mapOf(
                "status" to "stream_list_failed",
                "errorTypes" to errors,
                "error" to errors.joinToString(" -> "),
                "safeRequestSummary" to summarizeStreamRequests(
                    eu.kanade.tachiyomi.network.NetworkHelper
                        .requireInstance().streamRequestDiagnostics()
                )
            )
        }
    }

    /**
     * Only called for an explicitly selected playback source. Unlike the
     * diagnostic method this returns live URLs/headers to the player bridge.
     * Never include those values in diagnostic output or log messages.
     */
    fun resolvePlaybackStreams(
        packageName: String, episodeUrl: String, episodeName: String
    ): Map<String, Any?> {
        if (episodeUrl.isBlank() || episodeName.isBlank()) {
            return mapOf("status" to "invalid_episode_selection")
        }
        return try {
            performStreams(packageName, episodeUrl, episodeName, forPlayback = true)
        } catch (error: Throwable) {
            mapOf(
                "status" to "stream_list_failed",
                "error" to (error.cause ?: error).javaClass.simpleName
            )
        }
    }

    private fun performStreams(
        packageName: String, episodeUrl: String, episodeName: String,
        forPlayback: Boolean = false
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
        val pm = context.packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getApplicationInfo(packageName,
                PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        }
        val sourceName = info.metaData?.getString("tachiyomi.animeextension.class")
            ?: return mapOf("status" to "no_source_class")
        val entry = sourceName.split(';', ',').first().trim().let {
            if (it.startsWith(".")) packageName + it else it
        }
        val paths = listOfNotNull(info.sourceDir) + (info.splitSourceDirs?.toList() ?: emptyList())
        val extensionClasses = paths.flatMap { apk ->
            val dex = DexFile(apk)
            try {
                val names = mutableListOf<String>()
                val enumeration = dex.entries()
                while (enumeration.hasMoreElements()) names.add(enumeration.nextElement())
                names
            } finally { dex.close() }
        }.toSet()
        val loader = ExtensionIsolatedClassLoader(
            paths.joinToString(File.pathSeparator),
            context.codeCacheDir.absolutePath,
            info.nativeLibraryDir, context.javaClass.classLoader, extensionClasses
        )
        val instance = Class.forName(entry, true, loader).getDeclaredConstructor().newInstance()
        val source = instance as? AnimeSource
            ?: return mapOf("status" to "not_anime_source")
        val episode = eu.kanade.tachiyomi.animesource.model.SEpisode.create().apply {
            url = episodeUrl
            name = episodeName
        }
        // One opt-in test. Observe cache hits as well as network requests.
        helper.beginStreamDiagnostics()
        val videos = try {
            source.fetchVideoList(episode).toBlocking().toFuture()
                .get(35, TimeUnit.SECONDS)
        } finally {
            helper.endStreamDiagnostics()
        }
        if (forPlayback) {
            val playable = videos.take(40).mapNotNull { video ->
                val url = video.videoUrl
                val uri = try { android.net.Uri.parse(url) } catch (_: Exception) { null }
                if (uri == null || uri.scheme?.lowercase() !in setOf("http", "https") ||
                    uri.host.isNullOrBlank()) return@mapNotNull null
                val subtitle = video.subtitleTracks.firstOrNull()?.url
                val subtitleFormat = when {
                    subtitle?.substringBefore('?')?.endsWith(".ass", true) == true -> "ass"
                    subtitle?.substringBefore('?')?.endsWith(".srt", true) == true -> "srt"
                    subtitle?.substringBefore('?')?.endsWith(".vtt", true) == true -> "vtt"
                    else -> ""
                }
                mapOf(
                    "url" to url,
                    "quality" to video.videoTitle.ifBlank { "Auto" },
                    "server" to packageName.substringAfterLast('.'),
                    "headers" to (video.headers?.toMultimap()?.mapValues {
                        it.value.joinToString("; ")
                    } ?: emptyMap<String, String>()),
                    "subtitle" to (subtitle ?: ""),
                    "subtitleFormat" to subtitleFormat,
                    "audioTrackCount" to video.audioTracks.size,
                    "subtitleTrackCount" to video.subtitleTracks.size
                )
            }
            return mapOf(
                "status" to if (playable.isEmpty()) "stream_list_empty" else "stream_list_completed",
                "videos" to playable,
                "videoCount" to playable.size
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
            "videos" to videos.take(40).map { video ->
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
