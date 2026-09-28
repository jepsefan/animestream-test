# v1.4.8-beta17

> Test release fixing authenticated AniList-to-SIMKL ID lookup.

## Changes since beta16

### SIMKL authenticated lookup
- SIMKL anime search requests now include the saved SIMKL access token when available.
- SIMKL anime info requests use the same authenticated headers.
- Sends `Authorization: Bearer <token>`, `simkl-api-key`, and `Accept: application/json`.
- Keeps the beta16 lookup diagnostics so HTTP status, response data, result count, and resolved SIMKL ID remain visible in the APP log.
- Access tokens are never written to the log.

### Why
- Beta16 confirmed SIMKL returned HTTP 401 `user_token_required` because this client ID requires a user access token on every request.
- This allows the existing AnimeStream flow to resolve AniList ID -> SIMKL ID before SyncHandler updates SIMKL watch progress.
