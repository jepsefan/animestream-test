# v1.4.9-beta34.31 — Extension installation lifecycle

Based directly on beta34.30 (which branches from beta34.28; does not include beta34.29).

Changes:
- Refresh installed extension packages/versions when the catalog page returns to the foreground following Android's installer or permission screen.
- Add a manual refresh button to the repository page.
- Remove a false-negative `resolveActivity()` check: on Android 11+, package visibility can hide the package installer from resolution. Try the system installer and handle ActivityNotFoundException instead.
- Clean up verified installer cache files older than 24 hours on subsequent installation attempts, retaining recent files while Android may still be reading them.
- Extend shared source adapter's handling of wrapped Java execution errors.
- Bump version to `1.4.9-beta34.31+43`.

Unchanged:
- User-added repository URLs remain local.
- Android APK install still requires user consent.
- APK cryptographic verification and certificate SHA-256 pinning from beta34.30 remain required.
- Installed source approvals and [Ext] entries are pinned to installed APK signer + versionCode.

Limitations:
- **Not build-verified or device-tested yet.** GitHub Actions reported no runs for the beta34.30 branch at review time.
- Opening Android installer does not mean an installation succeeded. Only the subsequently refreshed PackageManager state can show that.
- This is not complete Anikku Host API parity or a promise all Yūzōnō extensions work.
- Version/update status currently comes from explicit catalog browsing, not a background polling service.

Tests: compile, browse local repo, tap Install, verify system installer, return and verify version updates, enable sources, restart, check the [Ext] selector; repeat with an old same-signer APK to verify Update, and ensure wrong-signature APKs are rejected.
