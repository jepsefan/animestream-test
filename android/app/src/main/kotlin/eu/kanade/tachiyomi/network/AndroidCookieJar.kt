package eu.kanade.tachiyomi.network

import android.webkit.CookieManager
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl

/**
 * Anikku-compatible CookieJar. WebView cookies are shared with OkHttp and
 * persisted by Android. On devices without a WebView provider (some TVs),
 * extension cookies remain session-only in a scoped in-memory fallback.
 *
 * No cookie values are sent to Flutter diagnostics or logcat.
 */
class AndroidCookieJar : CookieJar {
    private val memory = mutableListOf<Cookie>()
    private val lock = Any()
    private val manager: CookieManager? by lazy {
        try {
            CookieManager.getInstance()
        } catch (_: Throwable) {
            // Android TV images may have no system WebView implementation.
            null
        }
    }

    override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
        synchronized(lock) {
            for (cookie in cookies) {
                memory.removeAll { existing ->
                    existing.name == cookie.name &&
                        existing.domain == cookie.domain &&
                        existing.path == cookie.path
                }
                if (cookie.expiresAt > System.currentTimeMillis()) {
                    memory.add(cookie)
                }
            }
            val webCookies = manager
            if (webCookies != null) {
                for (cookie in cookies) {
                    try {
                        webCookies.setCookie(url.toString(), cookie.toString())
                    } catch (_: RuntimeException) {
                        // Continue with in-memory fallback.
                    }
                }
            }
        }
    }

    override fun loadForRequest(url: HttpUrl): List<Cookie> = get(url)

    fun get(url: HttpUrl): List<Cookie> {
        synchronized(lock) {
            memory.removeAll { it.expiresAt <= System.currentTimeMillis() }
            val result = linkedMapOf<String, Cookie>()
            for (cookie in memory) {
                if (cookie.matches(url)) {
                    result[cookie.name] = cookie
                }
            }
            val cookieHeader = try { manager?.getCookie(url.toString()) } catch (_: RuntimeException) {
                null
            }
            if (!cookieHeader.isNullOrBlank()) {
                for (part in cookieHeader.split(";")) {
                    // Android CookieManager returns name=value pairs, not full
                    // Set-Cookie headers; parse against the concrete request host.
                    Cookie.parse(url, part.trim())?.let {
                        if (it.matches(url)) result[it.name] = it
                    }
                }
            }
            return result.values.toList()
        }
    }

    fun remove(url: HttpUrl, cookieNames: List<String>? = null, maxAge: Int = -1): Int {
        synchronized(lock) {
            val matches = get(url)
                .filter { cookieNames == null || it.name in cookieNames }
            val names = matches.map { it.name }.toSet()
            memory.removeAll { it.matches(url) && it.name in names }
            val webCookies = manager
            if (webCookies != null) {
                for (cookie in matches) {
                    try {
                        // Limit removal to the cookie's original host/path.
                        val domainAttribute = if (cookie.hostOnly) "" else "; Domain=" + cookie.domain
                        webCookies.setCookie(url.toString(),
                            cookie.name + "=; Max-Age=" + maxAge +
                                "; Path=" + cookie.path + domainAttribute)
                    } catch (_: RuntimeException) {
                        // Ignore missing WebView implementation.
                    }
                }
            }
            return matches.size
        }
    }

    fun removeAll() {
        synchronized(lock) {
            memory.clear()
            try {
                manager?.removeAllCookies(null)
                manager?.flush()
            } catch (_: RuntimeException) {
                // Continue even when WebView is unavailable.
            }
        }
    }
}
