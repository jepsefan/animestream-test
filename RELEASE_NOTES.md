# AnimeStream — latest three beta releases

Only the three most recent beta versions are kept here. Older entries are in [CHANGELOG.md](CHANGELOG.md).

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

## v1.4.9-beta34.12 — AniList matching and manual episode diagnostics (unverified)
- Use AnimeStream's existing AniList API to rank extension search results against AniList English, romaji, native and synonym titles.
- Prioritize stronger potential matches, display AniList title and AniList cover when the match is sufficiently strong, preserve source title/URL, and flag uncertain matches for manual selection.
- Show individual extension results with source label, Sub/Dub indication and detected season.
- Add an opt-in Test episodes action per selected result, backed by Android Host API fetchEpisodeList(). Display names, numbers and source paths; does not fetch video URLs or add playable sources yet.
- AniList is still primary for metadata. No automatic binding of uncertain results to AniList IDs. Requires build and phone verification.
