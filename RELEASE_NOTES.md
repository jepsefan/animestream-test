# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.76, beta34.75 and beta34.74.

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

## v1.4.9-beta34.74 — SIMKL episode artwork in existing cache
- If a source has no episode thumbnail and the user has SIMKL connected, fetch the matched SIMKL anime's episode artwork as a fallback. Original source art wins; the anime cover remains the final fallback.
- Reuse the existing CacheManager and Hive network-cache box for SIMKL episode metadata **and image bytes**. App Cache Manager controls such as Clear all cache and maximum storage size apply; no independent image cache.
- Cache successfully found episode images with long retention; do not refresh them periodically. Only missing episode numbers are retried after 24h, and failed SIMKL fetches after 30min. Fetch an anime's episode list in one request; never make one API call per missing image.
- Verify SIMKL identity via the existing alternate database ID; never guess a match solely from a title. Ignore specials and ambiguous episode numbers. Only activate when a SIMKL token is present.
- Integrate mobile list/grid and desktop/TV artwork, asynchronously so failures cannot block playback or episode listing.
- Version `1.4.9-beta34.74+84`. APK build and SIMKL live response not yet verified. README unchanged.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
