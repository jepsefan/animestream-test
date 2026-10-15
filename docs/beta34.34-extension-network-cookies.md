# AnimeStream beta34.34 — Shared extension network sessions

Based directly on beta34.33; preserves beta34.32 extension browser, verified APK installation, source approvals and player.

## Implementation
- Added `eu.kanade.tachiyomi.network.AndroidCookieJar`, matching the Anikku package, class, and public cookie jar API (`get`, `remove`, `removeAll`).
- Integrated a single shared cookie jar with `NetworkHelper.client` so a source's search, episodes and stream requests can reuse cookies.
- Uses Android's `CookieManager` for WebView/HTTP cookie sharing where a WebView provider is available. Falls back to in-memory cookies for Android TV devices without a usable WebView.
- Does not include cookies or session tokens in network diagnostics.
- Added the missing `RequestsKt.PATCH` compatibility entry point with Anikku-compatible arguments and Kotlin default parameters.
- Updated pubspec to `1.4.9-beta34.34+46`.

## Remaining work
Full Anikku networking still needs compatible Cloudflare/WebView challenge handling, request interceptors, source preference screen UI and source-specific network settings. This beta does not promise every extension works. Network and cookie behavior, especially WebView on Android TV, requires testing.

## Build verification
Changes are committed to GitHub, but no Flutter/Gradle build was executed in this environment. Verify beta34.34 with GitHub Actions and on Android/Android TV before relying on it.

## Test
1. Build and install, without changing configured Yūzōnō catalog.
2. Select a previously approved `[Ext]` source, search, load episodes and attempt playback.
3. Switch sources, return, repeat without restarting AnimeStream.
4. Test on Android TV, which may lack a WebView implementation, ensuring the fallback does not crash.
5. Avoid sharing cookies, authorization values or signed media URLs in logs.
