# AnimeStream — latest three beta releases

Only the three most recent beta versions are kept here. When a new beta is added, the oldest entry moves to [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.3 — Better extension error diagnostics (unverified)
- Capture nested exceptions and stack traces for failed extension searches.
- Collapse verbose class diagnostics and clarify that playback is not yet supported.
- Added Android Application registration in Injekt before extension initialization; build and device test required.

## v1.4.9-beta34.2 — Extension search runtime dependencies (unverified)
- Added Injekt core runtime dependency and R8 keep rules for kotlinx.serialization classes.
- Added pre-search diagnostics for InjektKt and JsonObjectBuilder, reporting missing_host_runtime if absent.
- Search success is not yet verified; Android release build and device testing are required.

## v1.4.9-beta34 — Aniyomi extension search probe (unverified)
- Added an opt-in `Test search` field and confirmation dialog to Manage Providers for installed Aniyomi APKs.
- Added Flutter MethodChannel `testExtensionSearch` and an Android background-thread probe that attempts `fetchSearchAnime` through the isolated classloader.
- Search diagnostics return up to 20 titles, source URLs and cover URLs, or an error. The search operation has a 25-second wait limit.
- This is a diagnostic only: AniList remains the primary metadata source. No episode loading, stream playback or automatic matching is enabled.
- **Not yet build-verified or device-tested.** The partial Aniyomi Host API and filter ABI may still need changes.
