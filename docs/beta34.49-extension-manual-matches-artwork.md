# beta34.49 — Extension manual matches and episode artwork

Built on beta34.48. The earlier beta34.47 playback of AnimeOnsen [Ext] and Animenosub [Ext] was user-confirmed.

## Integration changes
- Both desktop and alternate manual-search dialogs use `InfoProvider.applyManualSourceSelection`. Only after the selected source returns episodes does it persist the manually confirmed source alias using the existing per-AniList/per-extension local preference.
- The source's cover URL (when valid HTTP(S)) can be reused for episode artwork in the current InfoProvider session. A per-episode thumbnail takes precedence; when unavailable, the extension cover takes precedence over the AniList cover.
- Existing automatic AniList matching constraints, the live extension episode and stream bridges, the AnimeOnsen HTTP 403 search fallback, and the subtitle renderer remain unchanged.

## Limitations and test plan
- **Not built or device tested**. Run a Flutter APK build and test manual selection of an ambiguous extension anime, page reopening (saved match), episode posters in both episode view modes, and video playback in AnimeOnsen [Ext] and Animenosub [Ext].
- Extension cover is currently session-level metadata; it is not yet persisted across re-launch independently of a new search. A previously saved source match still loads episodes without automatically retrieving source cover.
- The source's per-episode preview URL comes from its own extension response, when provided.
- Some subtitle characters (possibly Arabic) still display squares with crosses; intentionally deferred at the user's request.
- Version `1.4.9-beta34.49+60`.
