# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.90.5, beta34.90.4 and beta34.90.3.

## v1.4.9-beta34.90.5 — Experimental source browser verification
- Add a disabled-by-default experimental Web verification toggle in General settings.
- When the selected AnimePahe source fails to load episodes, display a Verify button. Open an embedded WebView for user-completed website verification.
- Save accepted website cookies locally with secure storage, restrict reuse to animepahe.pw HTTP requests, and use a consistent WebView/HTTP user-agent. Never log cookie values.
- Test the source's JSON API before closing verification. On success return to the series page and reload episodes without restarting the metadata page. Failed/cancelled verification leaves the selected provider unchanged.
- This is an experimental AnimePahe integration; website anti-bot checks may still reject API calls, and Aniyomi extension networking is not integrated.
- Version `1.4.9-beta34.90.5+121`. Android APK/device validation pending.

## v1.4.9-beta34.90.4 — Scrollable provider picker and TV focus
- Completed AniList anime cards now keep the existing dimmed poster but render score badges on a dark theme-derived background, with accent-colored star and score digits without white outlines for a cleaner look. Applies to standard and extended cards; other statuses remain unchanged. No extra AniList API calls.
- Keep the existing Select Provider bottom-sheet design, colors and source ordering.
- Constrain the provider list to the screen and enable touch scrolling for all providers.
- On Android TV, DPAD up/down moves focus between source rows, Scrollable.ensureVisible follows focus, and a contrast focus border shows which source has keyboard focus independently of the selected green source.
- Version `1.4.9-beta34.90.4+120`; APK build/device verification pending.

## v1.4.9-beta34.90.3 — MAL Recommended score fix
- Display missing MAL recommendation scores by lazily fetching `mean` alongside age ratings, with shared cached requests.
- Preserve Tenrai MAL Characters and Related changes from beta34.90.2.
- Version `1.4.9-beta34.90.3+119`; APK build not yet verified.
