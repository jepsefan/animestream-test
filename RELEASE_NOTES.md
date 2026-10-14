# AnimeStream — latest three beta releases

Only the three latest beta versions are kept here. Older entries are archived in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.20 — Subtitle selector and search fallback (build testing pending)
- Fix blank/grey subtitle track dialog by using the existing player and data notifiers across Navigator routes, with a constrained scrollable sheet and explicit colors.
- Preserve multi-language tracks, the Off option, libass ASS support, and long-press subtitle settings.
- When an Aniyomi search returns no results for a title ending in Season/Part/Cour N, also try the base title in automatic and manual searches.
- Do not link ambiguous source results automatically; manual series and season selection remains available.
- No changes to the working AnimeOnsen DASH playback pipeline.
- APK build and on-device tests not yet verified.

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
