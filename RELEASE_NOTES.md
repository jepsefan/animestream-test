# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.90.1, beta34.90 and beta34.89.

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

## v1.4.9-beta34.89 — Non-blocking MAL characters and related entries
- Fixed the beta34.88 series-page delay: Jikan characters no longer block initial metadata. Optional characters and relations load after the page appears, and each endpoint may fail independently without suppressing the other.
- Removed unsupported MAL anime details `related_manga` field and separated lightweight search/ranking fields from the detail request, preventing the MAL details request from discarding all metadata due to a field error.
- Fetch related adaptations, including manga and light novels, from Jikan's relations endpoint with a bounded cover lookup and an independent loading indicator. Non-anime entries remain non-playable.
- Character information and relations update the visible page when ready; existing Watch, playback, recommendation, source and rating behavior is unchanged.
- Version `1.4.9-beta34.89+115`. APK compilation and device verification pending.
