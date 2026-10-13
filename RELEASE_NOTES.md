# AnimeStream — latest three beta releases

Only the three most recent beta versions are kept here. When a new beta is added, the oldest entry moves to [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.4 — Aniyomi network and JSON host compatibility (unverified)
- Add Aniyomi-compatible RequestsKt HTTP helpers for 123Anime, including Kotlin default argument entry points.
- Register kotlinx.serialization.json.Json with the Injekt container before extension loading for AnimeOnsen.
- Fix visible literal newline escapes in extension source class labels.
- AnimePahe deferred because its website is unavailable. Build and device search remain to be tested; no playback or source matching yet.

## v1.4.9-beta34.3 — Better extension error diagnostics (unverified)
- Capture nested exceptions and stack traces for failed extension searches.
- Collapse verbose class diagnostics and clarify that playback is not yet supported.
- Added Android Application registration in Injekt before extension initialization; build and device test required.

## v1.4.9-beta34.2 — Extension search runtime dependencies (unverified)
- Added Injekt core runtime dependency and R8 keep rules for kotlinx.serialization classes.
- Added pre-search diagnostics for InjektKt and JsonObjectBuilder, reporting missing_host_runtime if absent.
- Search success is not yet verified; Android release build and device testing are required.
