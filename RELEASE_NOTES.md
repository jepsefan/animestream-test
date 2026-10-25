# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.90.9, beta34.90.8 and beta34.90.7.

## v1.4.9-beta34.90.9 — Hanime HLS playback compatibility
- Build `+128`: includes updated safe diagnostics and source-search failure classification for 123Anime and AnimeToki [Ext]. Beta version unchanged; Android compilation and device tests pending.
- Improve 123Anime/AnimeToki extension troubleshooting: log only sanitized native exception types and HTTP status codes; distinguish search failures from missing title matches. Offer Verify only when a source reports access-denial HTTP status rather than for every unsuccessful search. Original extension search implementations remain unchanged; device validation pending.
- Compilation fix: align `fvp_mdk.dart` with the new `VideoController.initiateVideo` named `shareWebViewCookies` parameter. MDK behavior unchanged; build remains `+128` after this bump.
- Build number raised to `+127` for a fresh APK including extension playback cookie forwarding; beta remains 34.90.9.
- Investigated actual Media3 `HTTP 403`: extension requests use Aniyomi's cookie-enabled OkHttp while BetterPlayer used a separate media client. Updated the BetterPlayer fork with opt-in, per-request, host-scoped Android WebView cookie forwarding for extension streams only; existing source headers retained, cookies excluded from Flutter bridges/logs. Source error remediation requires new APK/device test.
- Redact full network cache keys, signed media paths, and request queries in APP logs. Beta designation unchanged; included in build `1.4.9-beta34.90.9+127`.
- Build number updated to `+126` for a fresh APK with the BetterPlayer Media3 error diagnostics; beta version remains 34.90.9.
- Diagnostic update in the linked BetterPlayer fork: Media3 player errors now report sanitized error code, HTTP status when available, and exception type chain; never expose signed stream URLs or headers. Use the next PLAYER log to distinguish HTTP access denial from manifest/segment/decoder failures. Beta designation unchanged; APK and device validation pending.
- Build fix: restore the missing `extensionVerificationOutcome.dart` source required by Verify's status switch. No version bump; resolves missing import and related enum errors.
- Promote the existing hanime.tv [Ext] playback correction to a new beta: recognize signed, extensionless HLS playlist URLs and apply the HLS buffering profile automatically.
- Include the general extension Verify flow and separate missing-title diagnostics from the previous beta.
- Original solution applied to external sources. Version `1.4.9-beta34.90.9+128`; APK compilation and device playback still require testing.

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
