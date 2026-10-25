# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.90.7, beta34.90.6 and beta34.90.5.

## v1.4.9-beta34.90.7 — Playback
- Från originallösningen, tillämpad på extern källa.

## v1.4.9-beta34.90.6 — AnimePahe extension verification
- Dart compilation fix: remove 195 duplicate trailing lines accidentally left after `AniyomiExtensionProvider`'s closing brace. Prevents parser errors and misleading cascading `StateError` errors; version unchanged.
- Android build fix: pin `flutter_inappwebview_android` to `1.2.0-beta.3` for AGP 9 and validate the resolved package before compilation. App version remains `1.4.9-beta34.90.6+122`.
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
