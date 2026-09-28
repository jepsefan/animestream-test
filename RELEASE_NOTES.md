# v1.4.8-beta16

> Diagnostic test release focused on the AniList-to-SIMKL ID lookup.

## Changes since beta15

### SIMKL lookup diagnostics
- Added detailed APP-log output for the SIMKL anime search used to resolve an AniList anime to a SIMKL ID.
- Logs the AniList lookup query, HTTP status code, SIMKL response body, result count, and resolved SIMKL ID.
- Non-2xx search responses now include the HTTP status and response body in the thrown error.
- Unexpected SIMKL search response formats are logged explicitly.

### Purpose
- Helps diagnose why AnimeStream can sync AniList and MAL while SIMKL is missing from the SyncHandler list.
- Does not change the SIMKL V2 login or watch-history sync behavior.
