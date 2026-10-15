# Beta34.32 — Extensions library, sorting and uninstall

Base: beta34.31 (beta34.29 is excluded).

- Add native Android ACTION_DELETE through the extension MethodChannel; Android requires user confirmation and APK metadata must identify the target package as an anime extension. This is not the 'Disable sources' action.
- Flutter extension catalog adds **Installed / Updates / Browse** filters.
- Search by name, package or language.
- Filter and group results by extension language, sort names alphabetically, and show icons where available.
- Deduplicate multiple catalog entries by package, taking the highest catalog versionCode.
- Installed packages not in loaded repositories appear under **Installed outside catalogs**.
- Offer Uninstall under the package options; repository Remove still removes only the saved URL.
- Existing installation signature checks, local repo URLs, source activation, and Better Player are unchanged.
- Version 1.4.9-beta34.32+44.

**Verification:** Changes pushed; no Flutter/Android build or device tests run here. Uninstall is not guaranteed until confirmed in the Android system UI. The installed package list refreshes when the extension page resumes.
