# AnimeStream — Latest three beta development versions

The full development history is in [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.61, beta34.60 and beta34.59; older versions remain in the changelog.

## v1.4.9-beta34.61 — More titles in Discover
- Double the requested **Recently Updated** schedules (25 → 50) and **Recommended** entries (25 → 50). Filtering, duplicates and AniList availability can reduce the final number of visible cards.
- Expand **This Season** from 40 to up to 80 results using two AniList pages while leaving Home / Aired This Season unchanged at 40.
- Reset Discover lists on refresh to avoid accumulated duplicates. Manual Search Pagination has been rolled back to beta34.59; playback behavior is retained.
- Version `1.4.9-beta34.61+71`. **Build/device validation pending.**

## v1.4.9-beta34.60 — Manual Search pagination (reverted)
- Pagination was implemented experimentally in beta34.60.
- **Not included in beta34.61**: Manual Search, Host API search calls and related UI have been restored to the beta34.59 behavior.
- The expanded Discover sections introduced in beta34.61 remain enabled.

## v1.4.9-beta34.59 — Restore extension results in series pages
- The Manage Providers probe can resolve streams while the series page reports missing results because they use different source-selection paths; the probe normally omits a source ID, while the series view uses the saved approved ID.
- Forward the approved source's name and language during series-page search, episode retrieval and playback, allowing the already-implemented exact/unique identity fallback when its saved ID is stale after restart.
- Preserve existing AniList title matching, playback and subtitle handling; keep beta34.58's 20-second OLED dimming unchanged.
- Version `1.4.9-beta34.59+69`. **User-confirmed on device:** extension results now work in the series view after the source-identity change. Separate playback and pause-dimming regression checks have not yet been reported.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
