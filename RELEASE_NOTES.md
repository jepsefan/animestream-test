# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.90.6, beta34.90.5 and beta34.90.4.

## v1.4.9-beta34.90.6 — AnimePahe extension verification
- Promote the updated AnimePahe [Ext] verification flow to its own beta. Verify tests the selected Aniyomi extension using its OkHttp client and WebView-shared cookies, reports safe HTTP diagnostics and reloads episodes on success.
- Retain previous beta34.90.5 improvements and the existing experimental opt-in setting.
- Version `1.4.9-beta34.90.6+122`; APK/device validation pending.

## v1.4.9-beta34.90.5 — Experimental source browser verification
- AnimePahe [Ext] verification now tests the selected Aniyomi source through its own native OkHttp network stack using Android WebView-shared cookies and the same extension User-Agent. Verify only succeeds after a nonempty source search result; the page then retries episodes. Sanitize diagnostics to source host and HTTP status (403/429/503/network_error); no token or cookie logging. No app version change for this fix.
- Build fix: use flutter_inappwebview 6.2.0-beta.3 to avoid removed `proguard-android.txt` in Android Gradle Plugin 9; keeps version `1.4.9-beta34.90.5+121` unchanged.
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
