# AnimeStream — latest three beta releases

Only the three most recent beta versions are kept here. When a new beta is added, the oldest entry moves to [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34 — Aniyomi extension search probe (unverified)
- Added an opt-in `Test search` field and confirmation dialog to Manage Providers for installed Aniyomi APKs.
- Added Flutter MethodChannel `testExtensionSearch` and an Android background-thread probe that attempts `fetchSearchAnime` through the isolated classloader.
- Search diagnostics return up to 20 titles, source URLs and cover URLs, or an error. The search operation has a 25-second wait limit.
- This is a diagnostic only: AniList remains the primary metadata source. No episode loading, stream playback or automatic matching is enabled.
- **Not yet build-verified or device-tested.** The partial Aniyomi Host API and filter ABI may still need changes.

## v1.4.9-beta33.4 — Kotlin runtime and extension instantiation
- Added release keep rules for Kotlin runtime and coroutines classes used dynamically by Aniyomi APKs.
- User-provided Beta 33.4 diagnostics showed successful instance creation for 123Anime and AnimeOnsen; search and playback were not tested.

## v1.4.9-beta33.3 — Kotlin class visibility diagnostics
- Added Kotlin stdlib dependency and host/isolated classloader probes for Function0, Intrinsics, Unit and Continuation.
- User testing showed missing Kotlin runtime classes in release, motivating Beta 33.4.

