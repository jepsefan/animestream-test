# AnimeStream — latest three beta releases

Only the three latest beta versions are kept here. Older entries are archived in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.15 — Cache-aware stream stage inspection (unverified)
- For Test streams, use an application-level OkHttp interceptor so cached requests are recorded as well as network responses.
- For 123Anime, report server-tab count and safe presence/shape of episode-info target fields, without logging embed URLs, tokens, cookies, request query strings or media URLs.
- Show HTTP status, stage, cache flag and structural JSON information in stream diagnostics to distinguish empty metadata from unreachable player requests.
- No changes to stream routing, playback, or the successful AnimeOnsen extraction flow; build and device validation required.

## v1.4.9-beta34.14 — Stream extraction diagnostics (unverified)
- Distinguish empty stream responses from successful resolution: stream_list_empty instead of stream_list_completed when zero videos are found.
- Add sanitized, stage-based network request summaries for the 123Anime extraction flow to identify server-tab, video-info, player and playlist failures.
- Show an explicit diagnosis and HTTP-stage information in Test streams. Do not display full video URLs, signed paths, credentials or tokens.
- Preserve AnimeOnsen's working stream test and leave video playback unchanged.
- Build/device validation required.

## v1.4.9-beta34.13 — Manual extension stream diagnostics (unverified)
- Add Aniyomi legacy Video and Track models, plus Hoster compatibility constructors.
- Implement AnimeHttpSource.fetchVideoList() with extension-defined request and parser methods.
- Add opt-in Test streams for a selected episode after Test episodes in Manage Providers.
- Show video quality, format, stream host, track counts and status without exposing signed stream URLs, tokens, cookies or authorization headers.
- Does not start playback, download video, or connect extensions to AnimeStream's normal series pages.
- Both 123Anime and AnimeOnsen previously passed episode-list tests in beta34.12. Stream resolution remains unverified and may require more Host API components.
