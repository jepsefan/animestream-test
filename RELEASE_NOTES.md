# AnimeStream — latest three beta releases

Only the three latest beta versions are kept here. Older entries are archived in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.19 — Full Aniyomi external subtitle track selection (unverified)
- Preserve every subtitle track returned by an installed Aniyomi extension, including track language, label, format and URL.
- For extension streams with multiple tracks, the existing subtitle button opens a selector with each track and an Off option. Long-press still opens the usual subtitle settings.
- When an ASS/SSA track is selected on Android, use the existing libass overlay, retaining FPS and Motion Smoothing preferences; VTT/SRT remain in the regular renderer.
- Keep the chosen language when switching episode, source stream or quality if the new video has a matching track.
- Ordinary providers with only a single subtitle URL retain their previous toggle behavior; no change to video decoding.
- Builds and real-device subtitle selection/rendering have not yet been verified.

## v1.4.9-beta34.18 — Aniyomi search and DASH player fixes (device testing pending)
- Retry source searches against AniList's English, romaji, native and alternate titles (up to seven distinct queries). Never accept an unrelated catalog result; manual search remains available.
- Bypass HLS playlist extraction and HEAD/MIME probes for DASH .mpd manifests. Pass DASH directly to Better Player/ExoPlayer without premature HLS track selection.
- Present a visible player initialization error and Back to episodes action instead of hiding thrown errors on an empty player screen.
- Existing AniDB removal retained. Working conventional sources remain unchanged.
- Changes are unverified on Android; further troubleshooting may be needed for white video output and 123Anime matching.

## v1.4.9-beta34.17 — Remove retired AniDB sources (build validation pending)
- Remove built-in AniDB V1, V2 and V3 from the source selector.
- Delete the obsolete AniDB web scraping and video extraction implementation.
- Remove all AniDB V1/V2/V3 and legacy V3 alias registrations and the unused import.
- Existing AniList metadata integration, ordinary providers and Aniyomi extensions remain untouched.
- If AniDB was previously selected, the existing missing-provider fallback selects another available provider.
- Build and device validation pending.
