# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.90.2, beta34.90.1 and beta34.90.

## v1.4.9-beta34.90.2 — Tenrai MAL extras API
- MAL Recommended cards now fetch missing mean scores together with age ratings via one cached MAL API request per visible card; unknown scores remain `??`. Unit tests cover score conversion. No version bump for this incremental fix.
- Replace the discontinued Jikan public endpoint with Tenrai v1 for MAL Characters and Related requests.
- Retain the separate non-blocking loaders, diagnostic messages and lazy related cover fetching from beta34.90.1.
- Version `1.4.9-beta34.90.2+118`; API response validation and APK/device verification pending.

## v1.4.9-beta34.90.1 — Progressive MAL extras diagnostics
- Load MAL Characters and Related separately, so each section updates immediately on its own successful response.
- Remove the wait for up to eight MAL cover requests before publishing Related entries; each card retrieves its cover lazily and can display a text placeholder.
- Report character and relation request errors independently instead of silently treating network/rate-limit failures as empty results. Log counts and sanitized per-endpoint failures.
- Keep the series header responsive, preserve MAL manga/novel non-playable behavior and carry over beta34.90's compilation fix.
- Version `1.4.9-beta34.90.1+117`. APK and device verification pending.

## v1.4.9-beta34.90 — Fix MAL extras build
- Import `metadataTypes.dart` in `infoProvider.dart` so `AnimeMetadataSummary` resolves during release compilation.
- Retain beta34.89's non-blocking Characters/Related loading and update version to `1.4.9-beta34.90+116`.
- APK build and device testing not yet verified.
