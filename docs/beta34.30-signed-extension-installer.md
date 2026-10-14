# AnimeStream v1.4.9-beta34.30 — Signed extension installation

**Base is beta34.28**, deliberately excludes beta34.29 and its unrelated episode-loading changes.

## Implemented
- Install/Update in the manually configured Extension Repositories screen.
- Show installed version and compare Android `versionCode` with the repository index.
- User confirmation before downloading each extension APK.
- HTTPS APK retrieval (no redirects, same repository host/path, capped at 100 MiB).
- Cryptographic APK signature verification with the Android `apksig` library, pinned to version 8.9.2.
- Exact SHA-256 signing certificate comparison against the **locally approved** `repo.json` certificate.
- Check package name, Android APK versionCode and versionName against the selected catalog record.
- Reject changes to an installed extension's signing certificate and reject downgrades.
- Open the Android system installer using `FileProvider`. Android asks the user to approve; the response `installer_opened` does NOT mean installation completed. If permission is missing, Android opens Unknown App Sources settings.
- In Manage Providers, **Enable / refresh sources** saves source metadata per installed APK package, certificate fingerprint(s) and versionCode in local Hive. After restart, matching installed extensions appear individually as `[Ext]` without executing third-party APK code at startup. **Disable sources** revokes approval.
- Include both declared `tachiyomi.animeextension.class` and `tachiyomi.animeextension.factory` entry points in the shared host.

## Notes and limitations
- This release was **not** compiled or run on a physical device in the tool environment. Test an APK build before installation and check the release build with R8 enabled.
- Catalog metadata can be malicious; the downloaded binary must match the *user-approved* certificate exactly. Approving a fingerprint without independent publisher verification is a separate trust risk.
- Installation requires Android OS consent; refreshing installed extension inventory after a completed installation is currently done by tapping **Browse catalog** again.
- After updating an extension (changed versionCode), approve its sources again. Existing source activation is intentionally not silently transferred across an APK update.
- Full Anikku source-api binary/runtime parity, all hoster formats, cloudflare/webview hooks, cookies and preferences are not yet guaranteed. The factory-entry support is incremental.
- Not an automatic background updater; the user initiates installations and updates.
- If a repository uses off-host APK downloads or redirects, the secure installer currently blocks them instead of bypassing verification.

## Quick test
1. Build the branch and open Extension Repositories.
2. Load a locally added trusted Yūzōnō repository.
3. Check Install next to a not-yet-installed extension, approve download and Android installer.
4. Browse catalog again. The entry should display **Installed** and exact version.
5. Test updating an older signed extension and verify the update button.
6. Go to Manage Providers and choose **Enable / refresh sources**. Confirm individual `[Ext]` sources in the dropdown.
7. Restart the app; the same source entries should still be present. For security, reapprove following APK upgrades.
8. If any build errors or runtime install errors occur, capture Gradle output or sanitized diagnostics; never paste credentials/signed video URLs.
