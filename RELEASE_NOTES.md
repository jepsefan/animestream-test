# v1.4.8-beta18

> Test release using MyAnimeList as the primary external-ID lookup for SIMKL.

## Changes since beta17

### MAL -> SIMKL lookup test
- When AniList is the active database, AnimeStream now reads the existing MAL ID from the AniList info result first.
- SIMKL lookup is performed with `https://myanimelist.net/anime/<malId>` instead of the AniList URL in this beta.
- The APP log explicitly shows that MAL is being used as the SIMKL lookup source.
- Logs the MAL URL, result count, and resolved SIMKL ID.
- If no MAL ID is available, the log states that the SIMKL lookup was skipped.

### Intended follow-up behavior
- Beta18 is deliberately MAL-first so the MAL -> SIMKL mapping can be tested independently.
- After this path is verified, the intended normal behavior is AniList -> SIMKL first, then MAL -> SIMKL only when the AniList lookup returns zero results.
