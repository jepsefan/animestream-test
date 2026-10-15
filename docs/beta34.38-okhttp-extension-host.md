# Beta34.38 — OkHttp extension ABI

Base: beta34.37. This change addresses the observed `NoClassDefFoundError: eu.kanade.tachiyomi.network.OkHttpExtensionsKt` in AnimeOnsen stream retrieval.

- Adds `eu.kanade.tachiyomi.network.OkHttpExtensions.kt` with `Call.await()`, `Call.awaitSuccess()`, `Call.asObservable()`, `Call.asObservableSuccess()` and `HttpException`.
- Keeps successful OkHttp response bodies open for the caller and closes failed responses.
- Supports cancellation of coroutine HTTP calls and unsubscribe of Rx requests.
- This fixes the previously missing class and supplies core signatures; it is **not yet verified** that all API methods and Kotlin bytecode signatures match every extension version.
- Leaves existing installation, repository trust, and playback unchanged.

**Build/test not performed here.** Compile APK, repeat AnimeOnsen episode stream test, and review any new missing class, authentication error, HTTP response or playable video count. Do not share signed URLs or tokens.
