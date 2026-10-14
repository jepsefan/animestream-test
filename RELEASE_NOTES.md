# AnimeStream — latest three beta releases

Only the three latest beta versions are kept here. Older entries are archived in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.22 — AnimeOnsen ASS language selection; 123Anime stream diagnostics (not yet built)
- Use the documented AnimeOnsen /v4/subtitles/{id}/{locale}/{episode} endpoint to identify external subtitle tracks as ASS even without file extensions. Preserve all language choices.
- Default subtitle language to English when available, while respecting a manually selected language for the playback session.
- Keep AnimeOnsen DASH playback unchanged.
- Improve privacy-safe diagnostics when 123Anime finds episodes but returns no playable video sources; report request-stage/error-category information without media URLs, headers or tokens.
- This release does not claim to fix upstream 123Anime extraction failures. Build and device verification pending.

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
