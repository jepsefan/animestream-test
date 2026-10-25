# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.90.4, beta34.90.3 and beta34.90.2.

## v1.4.9-beta34.90.4 — Scrollable provider picker and TV focus
- Keep the existing Select Provider bottom-sheet design, colors and source ordering.
- Constrain the provider list to the screen and enable touch scrolling for all providers.
- On Android TV, DPAD up/down moves focus between source rows, Scrollable.ensureVisible follows focus, and a contrast focus border shows which source has keyboard focus independently of the selected green source.
- Version `1.4.9-beta34.90.4+120`; APK build/device verification pending.

## v1.4.9-beta34.90.3 — MAL Recommended score fix
- Display missing MAL recommendation scores by lazily fetching `mean` alongside age ratings, with shared cached requests.
- Preserve Tenrai MAL Characters and Related changes from beta34.90.2.
- Version `1.4.9-beta34.90.3+119`; APK build not yet verified.

## v1.4.9-beta34.90.2 — Tenrai MAL extras API
- MAL Recommended cards now fetch missing mean scores together with age ratings via one cached MAL API request per visible card; unknown scores remain `??`. Unit tests cover score conversion. No version bump for this incremental fix.
- Replace the discontinued Jikan public endpoint with Tenrai v1 for MAL Characters and Related requests.
- Retain the separate non-blocking loaders, diagnostic messages and lazy related cover fetching from beta34.90.1.
- Version `1.4.9-beta34.90.2+118`; API response validation and APK/device verification pending.
