# AnimeStream — latest three beta releases

Only the three most recent beta versions are kept here. When a new beta is added, the oldest entry moves to [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.5 — Aniyomi Host API compatibility (unverified)
- Add Aniyomi JsoupExtensionsKt parsing helpers for 123Anime.
- Add minimal NetworkHelper, protected AnimeHttpSource.getNetwork() access, and Injekt registration for AnimeOnsen.
- These are compatibility shims, not the full Aniyomi networking stack. Cloudflare handling and full cookie support are not implemented.
- Build and phone search still need verification. AnimePahe remains deferred.

## v1.4.9-beta34.4 — Aniyomi network and JSON host compatibility (unverified)
- Add Aniyomi-compatible RequestsKt HTTP helpers for 123Anime, including Kotlin default argument entry points.
- Register kotlinx.serialization.json.Json with the Injekt container before extension loading for AnimeOnsen.
- Fix visible literal newline escapes in extension source class labels.
- AnimePahe deferred because its website is unavailable. Build and device search remain to be tested; no playback or source matching yet.

## v1.4.9-beta34.3 — Better extension error diagnostics (unverified)
- Capture nested exceptions and stack traces for failed extension searches.
- Collapse verbose class diagnostics and clarify that playback is not yet supported.
- Added Android Application registration in Injekt before extension initialization; build and device test required.

