# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.79, beta34.78 and beta34.77.

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

## v1.4.9-beta34.77 — MAL OAuth login PKCE fix
- Fix MyAnimeList authorization to use `plain` PKCE with the same code challenge and code verifier, rather than sending an SHA-256 challenge that MAL does not support.
- URL-encode OAuth authorization parameters; validate the token response's HTTP status and JSON shape before parsing credentials. Show a useful HTTP-status error instead of a raw FormatException when MAL returns HTML.
- Apply safe response parsing to refresh-token requests. No changes to the MAL/Kitsu fallback, extensions, HLS audio, ASS delay, or existing cache.
- Version `1.4.9-beta34.77+87`. Login still depends on the OAuth redirect registered for the MAL client ID; build/device verification pending.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
