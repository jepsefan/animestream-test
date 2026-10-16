# Beta34.48 — Enable all installed extension sources

Base: beta34.47, with user-confirmed AnimeOnsen [Ext] and Animenosub [Ext] episode playback.

## What changed
- Settings → Manage Providers [Beta] → Installed has an **Enable all installed sources** button.
- Before running any newly discovered extension code, the user must approve a confirmation dialog naming all target APKs.
- Already-enabled sources are skipped. Remaining APKs are enabled sequentially through the **existing** `SourceManager.enableExtensionSources()` implementation, which verifies valid APK signing fingerprints, rechecks the installed signing fingerprint and versionCode after discovery, and persists source metadata to local Hive.
- A failure in one APK does not abort the whole batch. The UI shows progress, a success/skipped/failure summary and sanitized failure categories.
- The pre-existing single-source enable/disable controls remain. Nothing new runs automatically at app launch. Normal player and subtitle code remain unchanged.
- The provider manager explains the distinction between runnable approved Android extensions and stored-only Dart provider code.

## Testing
Not built or device tested. Build v1.4.9-beta34.48+59 and test enabling all installed extensions, seeing a trustworthy APK list, skipping approved ones, progress and failures, then restart and verify approved [Ext] sources persist. Recheck actual episode playback in AnimeOnsen [Ext] and Animenosub [Ext].

Known issue left unchanged by user request: some potentially Arabic subtitles show boxes with crosses.
