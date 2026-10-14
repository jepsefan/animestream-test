# v1.4.9-beta34.23 — Extension repository foundations

Based on `v1.4.9-beta34.21-extension-search-subtitle-formats`.

- Added local storage for manually entered Aniyomi-compatible repository URLs.
- Accepts HTTPS `index.min.json` URLs, HTTPS repository base URLs and pasted `aniyomi://add-repo?url=...` links.
- Parses `index.min.json` into extension metadata (name, package, version, language, optional source names, APK/icon URL).
- Added **Settings → Extension Repositories** screen for adding, removing and browsing saved catalogs.
- Yūzōnō is not preconfigured: the user explicitly adds a URL, which is saved in local Hive storage.
- Existing Flutter providers, Aniyomi APK detection, video playback and subtitle handling remain unchanged.

**Not implemented in this beta:** APK download/install/uninstall, APK signature/fingerprint trust checks, API-version compatibility checks, Anikku's production-grade extension loader, update notifications and full extension execution. Catalog entries deliberately have no installation button until trust verification is implemented.

**Build/testing:** Code committed on GitHub. No Flutter/Android build could be run in the current environment; compatibility and device behavior still require CI and Android/Android TV tests.

**Next compatibility work:** Port repository signing key validation + APK installation flow from Anikku, and replace the current minimal host API shim with a version-verified implementation. Audit dynamic loading and packaged dependencies before enabling arbitrary installed extensions.
