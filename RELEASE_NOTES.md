## v1.4.9-beta34.91+143 — Active Rewatch indicator
- Display `Rewatch On` above `Update Progress` when the series has an active SIMKL Rewatch session; leave AniList progress and Rewatch recording independent.
- +142 playback registration and skipped-episode behavior confirmed by user testing. APK build validation pending.

## v1.4.9-beta34.91+142 — Rewatch autoplay transition guard
- Avoid registering the next episode immediately when autoplay switches from the finished episode, by requiring the new episode to have been observed below the 75% watched threshold first.
- Keep exact-episode Rewatch writes and separate AniList/Rewatch markings. APK testing pending.

## v1.4.9-beta34.91+141 — SIMKL Rewatch exact episode fix
- Send the actual played episode number to an active SIMKL Rewatch session at the 75% watched threshold, independent of AniList progress.
- Prevent generic tracker progress from being written as a Rewatch episode; preserve primary tracker checkmarks and separate Rewatch glow.
- Avoid duplicate sends for the same episode in a player session. APK/device testing pending.

# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.91, beta34.90.9 and beta34.90.8.

## v1.4.9-beta34.91 — SIMKL Rewatch groundwork and glow preview
- Build +139: Add a guarded SIMKL Rewatch episode write using the pinned active rewatch_id, an explicit single episode, Pro/VIP eligibility, and session revalidation. Playback completion event integration is not yet wired; no automatic writes occur in this build.
- Build +138: Refresh read-only SIMKL Rewatch episode state after watch progress updates; during active sessions, watched checkmarks are based on explicitly watched session episodes, not inferred from the highest watched episode. Preserve primary database Continue from behavior. No Rewatch writes.
- Build +137: Parse watched episode numbers from the active SIMKL Rewatch entry's season-one episodes using nonempty watched_at. Keep read-only access and session-scoped glow; log matched episode count without dates.
- Build +136: Added safe diagnostics for the nested SIMKL seasons and episode list structures. No changes to Rewatch glow or history.
- Build `+135`: add read-only `[SIMKL REWATCH SHAPE]` diagnostics to identify the actual Rewatch episode payload structure (field names, types, list lengths, and one nested sample shape only). No account values, IDs, tokens, timestamps or full API payloads logged; no Rewatch writes or speculative episode-glow fallback.
- Build `+134`: episode glow is now gated by explicitly session-scoped Rewatch watched-episode numbers, with restored 30px circular glow area. Avoid applying glow to all historical watched episodes. The expected `rewatch_episodes` payload has not been verified against live SIMKL data; if absent, episode glow remains off. No history writes.
- Build `+133`: gate the existing watched-episode checkmark glow on a confirmed active SIMKL Rewatch session, matching Update Progress. Current watched markers are global progress, not verified session-specific episode history; no watch-history writes.
- Build `+132`: on series open, perform a nonblocking read-only SIMKL Rewatch discovery for VIP/PRO accounts using a 24-hour in-memory account-tier cache. Show the stronger theme-color glow around Update Progress only when an active session for that series is confirmed; keep episode checkmarks unglowed until session-specific watched episodes can be reliably identified. Invalidate account-tier cache on logout. No Rewatch writes; API response format and APK build still require validation.
- Build `+131`: disable the temporary episode-1 and Update Progress glow previews. Both stay off until a confirmed active SIMKL Rewatch session is integrated; no automatic Rewatch discovery or write is enabled yet.
- Build `+130`: detect SIMKL account tier from the existing `/users/settings` response and log privacy-safe subscription field presence/types (not values) to diagnose `UNKNOWN`. No additional API request. VIP/PRO/Free detection is provisional until confirmed on device; Rewatch remains read-only and UI glow is a visual preview.
- Version bumped to `1.4.9-beta34.91+129` to avoid an existing tag/build collision.
- Add an initial read-only SIMKL Rewatch session model and authenticated session-fetch method. It is not connected to the UI or automatic progress updates yet.
- Show the SIMKL account tier beside its name on the Account page using the existing profile response; unknown tiers display `UNKNOWN`. The tier detection still needs validation against SIMKL's actual response (device test displayed UNKNOWN).
- Add a visual-only theme-color glow around the watched checkmark of episode 1; reduce opacity from 85% to 55%, blur radius from 14 to 10 and spread radius from 3 to 1 after device feedback.
- Add the same glow as a visual-only preview around the Update Progress button while logged in. Neither glow reflects a real Rewatch session yet.
- Fix compilation errors caused by corrupted/duplicated Aniyomi extension search code and literal escaped newlines in SIMKL login code.
- Episode 1 glow was confirmed on Android before the latest softening; the updated glow and full APK build remain unverified.

## v1.4.9-beta34.90.9 — Hanime HLS playback compatibility
- Add targeted, redacted native extension search diagnostics for 123Anime and AnimeToki: status, exception type, result count/relevance, endpoint category, HTTP status and response type. No query text, full URLs or cookies are logged. Build number remains +128 pending compilation and device test.
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
