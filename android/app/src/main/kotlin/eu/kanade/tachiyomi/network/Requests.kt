@file:Suppress("FunctionName")

package eu.kanade.tachiyomi.network

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.CacheControl
import okhttp3.FormBody
import okhttp3.Headers
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.Response
import java.io.IOException
import java.util.concurrent.TimeUnit.MINUTES

/**
 * Aniyomi-compatible HTTP request entry points for externally installed extensions.
 *
 * Keep the top-level function names, argument order and Kotlin default arguments:
 * extension APKs call the generated RequestsKt.GET$default / POST$default methods.
 * No automatic Cloudflare bypass or login/cookie handling is provided here.
 */
private val DEFAULT_CACHE_CONTROL = CacheControl.Builder().maxAge(10, MINUTES).build()
private val DEFAULT_HEADERS = Headers.Builder().build()
private val DEFAULT_BODY: RequestBody = FormBody.Builder().build()

fun GET(
    url: String,
    headers: Headers = DEFAULT_HEADERS,
    cache: CacheControl = DEFAULT_CACHE_CONTROL,
): Request = GET(url.toHttpUrl(), headers, cache)

fun GET(
    url: HttpUrl,
    headers: Headers = DEFAULT_HEADERS,
    cache: CacheControl = DEFAULT_CACHE_CONTROL,
): Request = Request.Builder()
    .url(url)
    .headers(headers)
    .cacheControl(cache)
    .build()

fun POST(
    url: String,
    headers: Headers = DEFAULT_HEADERS,
    body: RequestBody = DEFAULT_BODY,
    cache: CacheControl = DEFAULT_CACHE_CONTROL,
): Request = Request.Builder()
    .url(url)
    .post(body)
    .headers(headers)
    .cacheControl(cache)
    .build()

fun PUT(
    url: String,
    headers: Headers = DEFAULT_HEADERS,
    body: RequestBody = DEFAULT_BODY,
    cache: CacheControl = DEFAULT_CACHE_CONTROL,
): Request = Request.Builder()
    .url(url)
    .put(body)
    .headers(headers)
    .cacheControl(cache)
    .build()

fun DELETE(
    url: String,
    headers: Headers = DEFAULT_HEADERS,
    body: RequestBody = DEFAULT_BODY,
    cache: CacheControl = DEFAULT_CACHE_CONTROL,
): Request = Request.Builder()
    .url(url)
    .delete(body)
    .headers(headers)
    .cacheControl(cache)
    .build()

private suspend fun OkHttpClient.executeChecked(request: Request): Response =
    withContext(Dispatchers.IO) {
        val response = newCall(request).execute()
        if (!response.isSuccessful) {
            val status = response.code
            response.close()
            throw IOException("HTTP $status")
        }
        response
    }

suspend fun OkHttpClient.get(
    url: String,
    headers: Headers = DEFAULT_HEADERS,
    cache: CacheControl = DEFAULT_CACHE_CONTROL,
): Response = executeChecked(GET(url, headers, cache))

suspend fun OkHttpClient.get(
    url: HttpUrl,
    headers: Headers = DEFAULT_HEADERS,
    cache: CacheControl = DEFAULT_CACHE_CONTROL,
): Response = executeChecked(GET(url, headers, cache))

suspend fun OkHttpClient.post(
    url: String,
    headers: Headers = DEFAULT_HEADERS,
    body: RequestBody = DEFAULT_BODY,
    cache: CacheControl = DEFAULT_CACHE_CONTROL,
): Response = executeChecked(POST(url, headers, body, cache))
