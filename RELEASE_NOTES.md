# AnimeStream — latest three beta releases

Only the three most recent beta versions are kept here. When a new beta is added, the oldest entry moves to [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.10 — Search endpoint diagnostics and alternate titles (unverified)
- Device testing confirmed 123Anime sends the exact keyword and receives HTTP 200 but may return unrelated catalogue entries for longer English searches.
- Device testing confirmed AnimeOnsen search receives HTTP 200 with Bearer authorization and returns four Japanese/romaji entries for Ascendance of a Bookworm.
- Do not classify these as incorrect solely because their Romanized titles do not contain the English search phrase.
- Show title relevance warnings without removing results. For 123Anime only, run a diagnostic comparison against /search?keyword= if no literal title matches are shown.
- This is a diagnostic-only probe; no permanent rewrite of installed extension requests, no automatic AniList matching, episodes or playback yet. Build/device testing required.

## v1.4.9-beta34.9 — Extension search diagnostics (unverified)
- Added privacy-safe request diagnostics: HTTP status, request host/path, authorization header presence (not token values), Cloudflare mitigation header and exact keyword comparison for 123Anime.
- Detect results that don't contain the requested phrase among displayed titles; show a warning instead of treating unrelated catalog results as verified search matches.
- AnimeOnsen may require a search token from its home page; HTTP 403 is not automatically an application or authentication error. Diagnostic-only; no Cloudflare bypass added.
- Keep existing extension runtime, ordinary sources, and all player behavior unchanged. Build/device verification required.

## v1.4.9-beta34.8 — Aniyomi JSON-Okio runtime (unverified)
- Add kotlinx-serialization-json-okio 1.9.0 and align kotlinx-serialization-json to 1.9.0, matching Aniyomi's JSON serialization version.
- Probe OkioStreamsKt before calling extensions to identify missing runtime dependency.
- Beta 34.7 device test confirmed 123Anime returns 28 results for Naruto; AnimeOnsen advanced past the Okio ABI error but now needs the serialization Okio bridge.
- Build/device verification still required; no episode loading or playback support yet.

