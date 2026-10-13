package eu.kanade.tachiyomi.network

import android.app.Application
import okhttp3.Cache
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
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
    @Volatile private var searchQuery: String? = null

    /**
     * Debug only: clear network status history for a manually initiated search.
     * Never retain token values, cookies, request bodies or query parameter values.
     */
    fun beginSearchDiagnostics(query: String) {
        synchronized(diagnosticLock) {
            networkHistory.clear()
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

    val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
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
