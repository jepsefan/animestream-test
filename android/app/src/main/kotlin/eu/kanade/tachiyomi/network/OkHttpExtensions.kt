package eu.kanade.tachiyomi.network

import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.Call
import okhttp3.Callback
import okhttp3.Response
import rx.Observable
import java.io.IOException
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/** Shared source-api ABI used by Anikku and Yuzono extension APKs. */
class HttpException(val code: Int) : IllegalStateException("HTTP error $code")

fun Call.asObservable(): Observable<Response> = Observable.unsafeCreate { subscriber ->
    val request = clone()
    val started = AtomicBoolean(false)
    subscriber.add(rx.subscriptions.Subscriptions.create { request.cancel() })
    subscriber.setProducer { n ->
        if (n > 0 && started.compareAndSet(false, true) && !subscriber.isUnsubscribed) {
            try {
                val response = request.execute()
                if (subscriber.isUnsubscribed) response.close()
                else {
                    subscriber.onNext(response)
                    if (!subscriber.isUnsubscribed) subscriber.onCompleted()
                }
            } catch (error: Exception) {
                if (!subscriber.isUnsubscribed) subscriber.onError(error)
            }
        }
    }
}

fun Call.asObservableSuccess(): Observable<Response> =
    asObservable().doOnNext { response ->
        if (!response.isSuccessful) {
            val code = response.code
            response.close()
            throw HttpException(code)
        }
    }

suspend fun Call.await(): Response = suspendCancellableCoroutine { continuation ->
    val call = this
    continuation.invokeOnCancellation { call.cancel() }
    call.enqueue(object : Callback {
        override fun onFailure(call: Call, e: IOException) {
            if (continuation.isActive) continuation.resumeWithException(e)
        }

        override fun onResponse(call: Call, response: Response) {
            if (continuation.isActive) {
                continuation.resume(response) { response.close() }
            } else {
                response.close()
            }
        }
    })
}

suspend fun Call.awaitSuccess(): Response {
    val response = await()
    if (!response.isSuccessful) {
        val code = response.code
        response.close()
        throw HttpException(code)
    }
    return response
}
