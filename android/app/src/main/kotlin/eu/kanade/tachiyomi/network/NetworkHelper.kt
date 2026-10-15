package eu.kanade.tachiyomi.network

import android.app.Application
import okhttp3.Cache
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import org.json.JSONObject
import org.jsoup.Jsoup
import java.io.IOException
import java.util.ArrayDeque
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Minimal Aniyomi-compatible NetworkHelper for dynamically loaded sources.
 *
 * Supports the class and getters referenced by older extensions. This does
 * not yet implement Aniyomi's Cloudflare, DoH, or persistent cookie services.
 */
class NetworkHelper(private val application: Application) {
    private val diagnosticLock = Any()
    private val networkHistory = ArrayDeque<Map<String, Any?>>()
    private val streamHistory = ArrayDeque<Map<String, Any?>>()
    @Volatile private var streamProbeActive = false

    /** Opt-in stream probe: include cache hits from the application interceptor. */
    fun beginStreamDiagnostics() {
        synchronized(diagnosticLock) {
            streamHistory.clear()
            streamProbeActive = true
        }
    }

    fun endStreamDiagnostics() { streamProbeActive = false }

    fun streamRequestDiagnostics(): List<Map<String, Any?>> =
        synchronized(diagnosticLock) { streamHistory.toList() }

    /**
     * Capture only redacted request stages and structural flags, NOT target
     * URLs, embed tokens, media URL query strings, cookies or response bodies.
     * This is an APPLICATION interceptor so cache hits remain visible.
     */
    private fun recordStreamRequest(request: Request, response: Response?) {
        if (!streamProbeActive) return
        val path = request.url.encodedPath
        val stage = when {
            path == "/ajax/film/sv" -> "server_tabs"
            path == "/ajax/episode/info" -> "episode_server_info"
            path.startsWith("/embed") -> "embed_wrapper"
            path.startsWith("/hs/getSources") -> "video_source_api"
            path.startsWith("/sbv2/getSources") -> "alternate_source_api"
            path.startsWith("/hs/") -> "player_page"
            path.startsWith("/sbv2/") -> "alternate_player_page"
            path.endsWith(".m3u8", ignoreCase = true) -> "hls_playlist"
            path.endsWith(".mpd", ignoreCase = true) -> "dash_manifest"
            path.contains("getSources", ignoreCase = true) -> "video_source_api"
            else -> "other_request"
        }
        val trace = mutableMapOf<String, Any?>(
            "stage" to stage,
            "host" to request.url.host,
            "status" to (response?.code?.toString() ?: "network_error"),
            "fromCache" to (response?.cacheResponse != null),
            "contentType" to (response?.header("Content-Type")
                ?.substringBefore(";")?.take(64) ?: "")
        )
        // Two known public JSON endpoints of 123Anime. The flags allow us
        // to distinguish an empty target from a network or player-page error.
        if (response != null && response.isSuccessful &&
            request.url.host == "123animehub.cc" &&
            (stage == "episode_server_info" || stage == "server_tabs")
        ) {
            try {
                val json = JSONObject(response.peekBody(32L * 1024L).string())
                trace["jsonObject"] = true
                if (stage == "episode_server_info") {
                    val target = json.optString("target").trim()
                    trace["targetPresent"] = target.isNotEmpty()
                    trace["targetIsHttp"] = target.startsWith("https://", true) ||
                        target.startsWith("http://", true)
                    trace["grabberPresent"] = json.optString("grabber").isNotBlank()
                    trace["typePresent"] = json.optString("type").isNotBlank()
                    // Safe shape classification, never store the actual target.
                    trace["targetShape"] = when {
                        target.isEmpty() -> "empty"
                        target.startsWith("https://", true) ||
                            target.startsWith("http://", true) -> "absolute_http"
                        target.startsWith("//") -> "scheme_relative"
                        target.startsWith("/") -> "relative_path"
                        else -> "other"
                    }
                } else {
                    val html = json.optString("html")
                    trace["serverTabCount"] = Jsoup.parse(html)
                        .select("span.tab[data-name]").size
                }
            } catch (_: Exception) {
                trace["jsonObject"] = false
            }
        }
        synchronized(diagnosticLock) {
            if (streamHistory.size >= 35) streamHistory.removeFirst()
            streamHistory.addLast(trace)
        }
    }
    @Volatile private var searchQuery: String? = null

    /**
     * Debug only: clear network status history for a manually initiated search.
     * Never retain token values, cookies, request bodies or query parameter values.
     */
    fun beginSearchDiagnostics(query: String) {
        synchronized(diagnosticLock) {
            networkHistory.clear()
            streamProbeActive = false
            searchQuery = query.trim()
        }
    }

    fun searchNetworkDiagnostics(): List<Map<String, Any?>> =
        synchronized(diagnosticLock) { networkHistory.toList() }

    private fun recordNetworkRequest(request: Request, response: Response?) {
        val auth = request.header("Authorization")
        val authState = when {
            auth == null -> "absent"
            auth.startsWith("Bearer ", ignoreCase = true) && auth.substring(7).isBlank() ->
                "empty_bearer"
            auth.startsWith("Bearer ", ignoreCase = true) -> "bearer_present"
            else -> "other_present"
        }
        val trace = mutableMapOf<String, Any?>(
            "method" to request.method,
            "host" to request.url.host,
            "path" to request.url.encodedPath,
            "status" to (response?.code ?: "network_error"),
            "authorization" to authState
        )
        // Only compare the incoming keyword with the requested query. Never log either.
        if ("keyword" in request.url.queryParameterNames) {
            trace["keywordMatchesQuery"] =
                request.url.queryParameter("keyword")?.trim()?.equals(
                    searchQuery?.trim(), ignoreCase = true
                ) == true
        }
        response?.header("Content-Type")?.let {
            trace["contentType"] = it.substringBefore(";").take(64)
        }
        response?.header("Server")?.let { trace["server"] = it.take(64) }
        response?.header("cf-mitigated")?.let { trace["cfMitigated"] = it.take(32) }
        synchronized(diagnosticLock) {
            if (networkHistory.size >= 12) networkHistory.removeFirst()
            networkHistory.addLast(trace)
        }
    }
    private val userAgent: String =
        "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 " +
            "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"

    val cookieJar: AndroidCookieJar by lazy { AndroidCookieJar() }

    val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .cookieJar(cookieJar)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .callTimeout(2, TimeUnit.MINUTES)
            .cache(Cache(File(application.cacheDir, "aniyomi_network_cache"), 5L * 1024L * 1024L))
            .addInterceptor { chain ->
                val request = chain.request()
                val withUserAgent = if (request.header("User-Agent") == null) {
                    request.newBuilder().header("User-Agent", defaultUserAgentProvider()).build()
                } else {
                    request
                }
                chain.proceed(withUserAgent)
            }
            // Runs outside OkHttp's cache layer, so stream diagnostics also
            // capture requests satisfied from cache. Does not modify responses.
            .addInterceptor { chain ->
                val request = chain.request()
                try {
                    val response = chain.proceed(request)
                    recordStreamRequest(request, response)
                    response
                } catch (error: IOException) {
                    recordStreamRequest(request, null)
                    throw error
                }
            }
            // Runs after extension-provided interceptors. Therefore diagnostics can
            // distinguish a valid Bearer header from "Bearer " without exposing it.
            .addNetworkInterceptor { chain ->
                val request = chain.request()
                try {
                    val response = chain.proceed(request)
                    recordNetworkRequest(request, response)
                    response
                } catch (error: IOException) {
                    recordNetworkRequest(request, null)
                    throw error
                }
            }
            .build()
    }

    @Deprecated("Use client: this bridge does not implement Cloudflare bypass")
    val cloudflareClient: OkHttpClient get() = client

    fun defaultUserAgentProvider(): String = userAgent

    companion object {
        @Volatile
        private var active: NetworkHelper? = null

        @Synchronized
        fun initialize(application: Application): NetworkHelper =
            active ?: NetworkHelper(application).also { active = it }

        fun requireInstance(): NetworkHelper =
            active ?: error("Aniyomi NetworkHelper is not initialized")
    }
}
