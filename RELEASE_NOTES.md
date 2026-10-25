# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.90.9, beta34.90.8 and beta34.90.7.

## v1.4.9-beta34.90.9 — Hanime HLS playback compatibility
- Promote the existing hanime.tv [Ext] playback correction to a new beta: recognize signed, extensionless HLS playlist URLs and apply the HLS buffering profile automatically.
- Include the general extension Verify flow and separate missing-title diagnostics from the previous beta.
- Original solution applied to external sources. Version `1.4.9-beta34.90.9+125`; APK compilation and device playback still require testing.

## v1.4.9-beta34.90.8 — General extension verification
- Extension playback fix: recognize the original hanime.tv extension's signed, extensionless `/hls/{id}/{token}` playlists as HLS before HEAD probing; retain source-supplied headers, distinguish other streaming formats, and add format-detection regression tests. Browser verification alone does not guarantee media CDN access; Android playback still requires testing.
- Verify now distinguishes completed searches with no matching title from network/access failures instead of suggesting the website challenge failed.
- Automatically apply the HLS buffer profile only to detected HLS playlists (`.m3u8`/`.m3u` or HLS MIME type), for built-in and external sources alike. DASH and direct files retain default buffer settings; direct file detection avoids unnecessary HEAD requests. The single-seek timeline behavior remains in place. No version bump.
- General Verify for user-approved Aniyomi/Anikku HTTP extensions when source episode lookup fails, using the extension's declared public HTTPS base domain and User-Agent.
- Browser verification is manual and remains opt-in. The selected extension's own search through the native OkHttp runtime validates access before returning to the series page to retry episodes.
- Android WebView and the existing AndroidCookieJar share website-scoped cookies; no cookies or sensitive URLs are passed to Flutter logs. Sources without a supported public HTTPS base URL display an unsupported message.
- Original solution applied to external sources. Version `1.4.9-beta34.90.8+124`; build and device validation pending.

## v1.4.9-beta34.90.7 — Playback
- Från originallösningen, tillämpad på extern källa.
