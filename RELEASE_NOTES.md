# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.90, beta34.89 and beta34.88.

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

## v1.4.9-beta34.88 — MAL Related and Characters
- When MAL supplies series metadata, Related now includes both anime and manga/light-novel adaptations from MAL API v2; relation labels are preserved.
- MAL character cards load independently from Jikan's MAL character endpoint with an eight-second timeout and twelve-hour cache. Failure leaves only Characters empty without losing series details.
- Manga and light-novel adaptation cards are marked non-playable, retaining the existing guard against opening those entries as anime.
- Added regression tests for manga/adaptation and anime/sequel relation parsing.
- Version `1.4.9-beta34.88+114`. Flutter build and APK/device verification pending.
