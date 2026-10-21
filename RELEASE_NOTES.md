# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.77, beta34.76 and beta34.75.

## v1.4.9-beta34.77 — MAL OAuth login PKCE fix
- Fix MyAnimeList authorization to use `plain` PKCE with the same code challenge and code verifier, rather than sending an SHA-256 challenge that MAL does not support.
- URL-encode OAuth authorization parameters; validate the token response's HTTP status and JSON shape before parsing credentials. Show a useful HTTP-status error instead of a raw FormatException when MAL returns HTML.
- Apply safe response parsing to refresh-token requests. No changes to the MAL/Kitsu fallback, extensions, HLS audio, ASS delay, or existing cache.
- Version `1.4.9-beta34.77+87`. Login still depends on the OAuth redirect registered for the MAL client ID; build/device verification pending.

## v1.4.9-beta34.76 — AniList metadata outage fallback (anime)
- Use read-only MAL v2 as first fallback and Kitsu as second for anime search, trending, currently airing and recently updated when AniList API fails.
- Adapt sofikuw/anImestream's anime metadata router and providers without depending on manga classes absent from this fork.
- Encode MAL/Kitsu IDs as separate negative application IDs; fallback result details resolve via their actual provider rather than issuing AniList GraphQL requests.
- Suppress AniList/SIMKL cross-database ID lookup for fallback-only entries to avoid accidental metadata/list ID corruption. Original source player and subtitle functionality remains intact.
- Existing positive AniList IDs do not yet dynamically remap to MAL on detail-fetch failure; no manga or configurable metadata toggles in this first port.
- Version `1.4.9-beta34.76+86`. APK compilation/device testing is not yet verified.

## v1.4.9-beta34.75 — Hourly cooldown for missing SIMKL episode images
- Retry missing SIMKL artwork no more than once an hour **per episode**, independently from all other episodes. Failed SIMKL requests use the same one-hour retry. Found artwork remains long-lived and is not refreshed on a timer.
- The selected streaming source defines the eligible episode list. SIMKL cannot trigger prefetch of future episodes (e.g. episode 16 while the selected provider only lists episodes 1–15).
- Newly added source episodes can be queried immediately without waiting for older episodes' cooldowns. One series-wide SIMKL request can resolve several eligible episodes at once.
- Keep the existing shared CacheManager/Hive image and metadata storage, cache controls, size limits and clear actions. Safely migrate positive art from beta34.74 while discarding the older series-wide cooldown.
- Version `1.4.9-beta34.75+85`. APK build and live SIMKL endpoint remain unverified. README unchanged.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
