# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.78, beta34.77 and beta34.76.

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

## v1.4.9-beta34.76 — AniList metadata outage fallback (anime)
- Use read-only MAL v2 as first fallback and Kitsu as second for anime search, trending, currently airing and recently updated when AniList API fails.
- Adapt sofikuw/anImestream's anime metadata router and providers without depending on manga classes absent from this fork.
- Encode MAL/Kitsu IDs as separate negative application IDs; fallback result details resolve via their actual provider rather than issuing AniList GraphQL requests.
- Suppress AniList/SIMKL cross-database ID lookup for fallback-only entries to avoid accidental metadata/list ID corruption. Original source player and subtitle functionality remains intact.
- Existing positive AniList IDs do not yet dynamically remap to MAL on detail-fetch failure; no manga or configurable metadata toggles in this first port.
- Version `1.4.9-beta34.76+86`. APK compilation/device testing is not yet verified.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
