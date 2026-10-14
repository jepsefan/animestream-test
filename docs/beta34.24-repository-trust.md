# v1.4.9-beta34.24 — Repository trust and metadata verification

Based on beta34.23 (which itself branches from the user-selected beta34.21).

- Added Anikku-style `repo.json` metadata inspection.
- Show repo name and SHA-256 signing-key fingerprint in an explicit trust dialog.
- Pin approved fingerprints only in local Hive storage; no Yūzōnō URL is hard-coded.
- Re-fetch repository metadata to detect a changed fingerprint before browsing.
- Previously saved beta34.23 records have no pinned key and require reapproval.
- Repository metadata requests disallow redirects and enforce response-size/time limits.
- Existing sources, extension testing, players and subtitle renderers are unchanged.

**Security note:** This validates the consistency of repository metadata against a key approved by the user. It does *not* yet cryptographically verify an APK, establish the publisher's real identity, or guarantee an extension is safe. Only approve a fingerprint after independent verification.

**Not yet implemented:** Downloading and installing APKs, matching downloaded APK certificate SHA-256 against the pinned fingerprint, installed-extension trust enforcement, ABI compatibility updates and complete Anikku Host API behavior. These must be implemented before presenting a working installation button.

**Build verification:** Not run in this environment. Android and Android TV testing / GitHub Actions must still be completed.
