# AnimeStream v1.4.9-beta34.92

Integrates upstream [v1.4.8-beta5](https://github.com/frostnova721/animestream/releases/tag/v1.4.8-beta5) into the fork's embed stream diagnostics branch.

- Adds ReAnime and updates AniZone parsing.
- Adds a local watch tracker that imports existing local viewing history. The info page loads watch progress separately from anime details.
- Adds batch downloads, DASH downloads, and downloads with separate audio tracks.
- Adds native player audio selection, improves HLS parsing, and reduces stutter when dragging the seek bar.
- Carries forward Android TV remote controls, Aniyomi stream diagnostics, and external ASS/SSA, SRT and VTT subtitle selection.

## v1.4.9-beta34.21 — Subtitle format identification and Aniyomi searches (not yet built)
- Identify extension subtitle format (ASS/SSA, WebVTT or SRT) using a bounded sample of actual subtitle content when the URL/label does not reveal its format.
- Show detected format progressively next to each language in the subtitle picker. Never assume an unknown format is ASS, and do not route unknown formats to the libass overlay.
- Keep the working AnimeOnsen DASH playback path unchanged.
- Retry extension searches with base title and punctuation-free variants (such as removing "Season 2"), but do not automatically bind unrelated or ambiguous seasons.
- Build and on-device tests are pending; 123Anime may still require manual source selection or a source-side fix.

## v1.4.9-beta34.20 — Subtitle selector and search fallback (build testing pending)
- Fix blank/grey subtitle track dialog by using the existing player and data notifiers across Navigator routes, with a constrained scrollable sheet and explicit colors.
- Preserve multi-language tracks, the Off option, libass ASS support, and long-press subtitle settings.
- When an Aniyomi search returns no results for a title ending in Season/Part/Cour N, also try the base title in automatic and manual searches.
- Do not link ambiguous source results automatically; manual series and season selection remains available.
- No changes to the working AnimeOnsen DASH playback pipeline.
- APK build and on-device tests not yet verified.
