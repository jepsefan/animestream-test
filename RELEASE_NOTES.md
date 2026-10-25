# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.90.8, beta34.90.7 and beta34.90.6.

## v1.4.9-beta34.90.8 — General extension verification
- Automatically apply the HLS buffer profile only to detected HLS playlists (`.m3u8`/`.m3u` or HLS MIME type), for built-in and external sources alike. DASH and direct files retain default buffer settings; direct file detection avoids unnecessary HEAD requests. The single-seek timeline behavior remains in place. No version bump.
- General Verify for user-approved Aniyomi/Anikku HTTP extensions when source episode lookup fails, using the extension's declared public HTTPS base domain and User-Agent.
- Browser verification is manual and remains opt-in. The selected extension's own search through the native OkHttp runtime validates access before returning to the series page to retry episodes.
- Android WebView and the existing AndroidCookieJar share website-scoped cookies; no cookies or sensitive URLs are passed to Flutter logs. Sources without a supported public HTTPS base URL display an unsupported message.
- Original solution applied to external sources. Version `1.4.9-beta34.90.8+124`; build and device validation pending.

## v1.4.9-beta34.90.7 — Playback
- Från originallösningen, tillämpad på extern källa.

## v1.4.9-beta34.90.6 — AnimePahe extension verification
- Dart compilation fix: remove 195 duplicate trailing lines accidentally left after `AniyomiExtensionProvider`'s closing brace. Prevents parser errors and misleading cascading `StateError` errors; version unchanged.
- Android build fix: pin `flutter_inappwebview_android` to `1.2.0-beta.3` for AGP 9 and validate the resolved package before compilation. App version remains `1.4.9-beta34.90.6+122`.
- Promote the updated AnimePahe [Ext] verification flow to its own beta. Verify tests the selected Aniyomi extension using its OkHttp client and WebView-shared cookies, reports safe HTTP diagnostics and reloads episodes on success.
- Retain previous beta34.90.5 improvements and the existing experimental opt-in setting.
- Version `1.4.9-beta34.90.6+122`; APK/device validation pending.
