# AnimeStream — latest three beta releases

Only the three most recent beta versions are kept here. Older beta notes are archived in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.11 — 123Anime search routing and alternate titles (unverified)
- Route only plain text searches in the installed 123Anime extension to /search instead of /filter when the original source request uses the broken browse-list endpoint.
- Preserve the extension's original search parser and its existing result titles, URLs and cover addresses. Advanced filtered searches and other sources are not redirected.
- Mark AnimeOnsen's Japanese/romaji search hits as possible alternate titles, not automatically unrelated. AniList remains authoritative for matching.
- Avoid redundant 123Anime endpoint probes when the actual request already uses /search.
- Build and phone tests are still required. This does not implement episode or stream loading.

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
