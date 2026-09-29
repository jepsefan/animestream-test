# v1.4.8-beta19

> SIMKL external-ID lookup now uses AniList first with MyAnimeList as fallback.

## Changes since beta18

### AniList -> SIMKL primary lookup
- When AniList is the active database, AnimeStream first searches SIMKL using `https://anilist.co/anime/<id>`.
- The APP log explicitly shows that AniList is being used as the primary SIMKL lookup source.

### MAL -> SIMKL fallback
- If the AniList lookup succeeds but returns `results=0`, AnimeStream reads the MAL ID already provided by AniList.
- It then retries SIMKL lookup with `https://myanimelist.net/anime/<malId>`.
- The APP log shows when the fallback is triggered, the MAL URL used, the result count, and the resolved SIMKL ID.
- If no MAL ID exists, the log states that the fallback was skipped.

### Logging
- Keeps the authenticated SIMKL request diagnostics from beta16/beta17.
- Typical successful fallback sequence:
  `AniList -> SIMKL results=0`
  `AniList results=0 -> MAL fallback`
  `MAL -> SIMKL results=1`
  `resolved simklId=...`

### VTT stacked subtitle colors
- Added visual separation for overlapping VTT cues in the normal bottom subtitle stack.
- The newest/bottom cue is white.
- The cue above it is light gray (`#D0D0D0`).
- Older cues use gray (`#9E9E9E`).
- This only affects VTT cues in bottom-aligned groups; status/UI cues and ASS rendering keep their existing behavior.

