package eu.kanade.tachiyomi.network

import android.app.Application
import okhttp3.Cache
import okhttp3.OkHttpClient
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Minimal Aniyomi-compatible NetworkHelper for dynamically loaded sources.
 *
 * Supports the class and getters referenced by older extensions. This does
 * not yet implement Aniyomi's Cloudflare, DoH, or persistent cookie services.
 */
class NetworkHelper(private val application: Application) {
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
