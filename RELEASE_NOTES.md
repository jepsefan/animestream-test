# AnimeStream — latest three beta releases

Only the three latest beta versions are kept here. Older entries are archived in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.22 — Local AniYomi repository setting
- Let the user enter an AniYomi HTTPS JSON index URL in Extensions and store it locally on the device; no repository URL is bundled in the app.
- Show language, source, version, and NSFW metadata for entries from the selected repository.
- Download an extension APK and open Android's package installer; refresh Installed after installation to search and use it through the existing `[Ext]` source flow.
- Keep installed extension search, AniList ranking, episode selection, streams, and subtitle handling in the Extensions screen.
- Keep the separate experimental Dart-provider catalog available without mixing its entries into AniYomi extensions.
- No Flutter build or on-device APK installation test has been performed yet.

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
