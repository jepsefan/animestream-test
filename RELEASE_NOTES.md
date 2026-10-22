# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.80, beta34.79 and beta34.78.

## v1.4.9-beta34.80 — Complete extension episodes and safer search matching
- Separate Android extension episode diagnostics from player episode loading: **Manage Providers** diagnostics retain the first 100 entries and the total-count/truncation indicator; the regular series-page playback bridge now transfers the full episode list returned by the approved extension, so long-running series are no longer silently cut off at episode 100.
- Fix Dart extension search to read the actual Android `resultRelevance` field (rather than the nonexistent `relevance` field). An unverified, unrelated browse/catalogue response is no longer accepted as a normal title-search match; manual selection and the existing AnimeOnsen 403 search workaround remain available.
- Keep existing extension APK approvals, source settings, stream hoster resolution, subtitle/audio playback, SIMKL integration and metadata fallbacks unchanged.
- Version `1.4.9-beta34.80+90`. Flutter/Android compilation and device behavior have not been verified.

## v1.4.9-beta34.79 — Built-in provider and metadata controls
- Add **General → Built-in providers** between **Manage Providers** and **Cache Manager**, based on sofikuw/anImestream's provider settings page but adapted to the anime-only fork.
- Toggle built-in **AnimeOnsen, AniZone, Anikoto and Animegg** on or off without uninstalling extensions. Persist the disabled list in existing Hive Settings and restore it on startup. AniDB remains removed.
- Add **AniList, MyAnimeList and SIMKL** metadata controls and separately enable/disable the **MyAnimeList → Kitsu** fallback order. Disabling AniList routes supported discovery searches to enabled fallbacks; existing positive AniList IDs are not remapped to fallback IDs.
- SIMKL metadata control suppresses the series-page SIMKL cross-ID enrichment lookup, but does not log out the user or alter the SIMKL image cache. The previously identified AniList-login dependency for SIMKL episode artwork is intentionally left unchanged.
- Preserve APK repository management, approved extensions, existing playback and cache functionality. If a disabled built-in was the default source, switch the default to the first remaining available source when possible.
- Version `1.4.9-beta34.79+89`. Flutter compilation and device testing have not been verified.

## v1.4.9-beta34.78 — Extension repositories in Manage Providers > Available
- Move the existing Aniyomi extension repository interface into the **Available** tab of **Manage Providers [Beta]**. The tab now displays repository URL entry, trusted repository management, extension search, Installed / Updates / Browse filters, language filtering, and APK installation, updates and uninstallation instead of the older available Dart provider list.
- Embed the repository screen without a second app bar or navigation page; add an in-tab refresh control for repository catalogs and Android-installed extensions.
- Remove the separate **Extension Repositories** entry from Settings. The **Installed** tab retains its existing installed APK/source approval and diagnostic controls, as well as saved Dart providers.
- Reuse the existing local repository URLs, trusted certificate fingerprints and APK signature-verification process. No default external repositories are added and no repository storage migration is required.
- Version `1.4.9-beta34.78+88`. APK compilation and Android/mobile/TV UI testing have not yet been verified.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
