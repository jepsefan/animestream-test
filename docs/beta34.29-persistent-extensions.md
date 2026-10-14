# Beta34.29 — Persistent sources and manual episode selection

Based on beta34.28.

## Fixes
- User-approved extension source IDs now persist in a local Hive box.
- Restore requires an installed APK with the exact same package, APK-signing certificate SHA-256 fingerprint(s), and Android versionCode. Changed/uninstalled/unsigned extensions are not restored.
- Restoration reads saved source metadata without automatically instantiating third-party APK code at application startup. Sources only execute when the user explicitly invokes them.
- "Enable / refresh sources" and "Disable sources" are available in Manage Providers.
- Manual Search selection now goes through a single InfoProvider method across mobile and source widgets, loads episodes immediately, and saves the extension title selection when loading succeeds.
- Generation tokens prevent older automatic search requests from overwriting a later manual episode list or a newly selected provider.
- Version: 1.4.9-beta34.29+41.

## Verification
- Code pushed to GitHub; no Flutter/Gradle or on-device tests have been performed for beta34.29.
- Upgrading from beta34.28 requires **one more manual extension enable** because previous builds never persisted approvals. Subsequent restarts should restore those sources automatically.
- An APK certificate fingerprint recorded here proves consistency with the *user-approved installed binary*, but does not independently prove the publisher's identity or that third-party code is safe.
- This change does not install APKs or implement the complete Anikku Host API.

## Test procedure
1. Open Manage Providers, select an installed trusted extension and tap Enable / refresh sources.
2. Use a source marked [Ext], manually select an anime title, and check whether episode numbers appear without restarting.
3. Fully close and reopen AnimeStream. The [Ext] source should remain visible without re-enabling.
4. Repeat Manual Search, select another anime, and verify its episode list is updated without needing restart.
5. If an extension APK is upgraded, its versionCode changes, or its signing certificate changes, reapprove the extension before using its sources.
