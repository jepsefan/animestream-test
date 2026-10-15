# AnimeStream beta34.35 — Catalog loading, uninstall and stream diagnostics

Based on beta34.34, preserving local trusted repositories and signature-checked APK installation.

- Loads all previously approved repository indexes when the extension catalog screen opens (not just their saved URLs).
- Adds a loading indicator and surfaces fetch errors beside repository URLs. Browse now includes installed *and* uninstalled extensions.
- Uses Android ACTION_UNINSTALL_PACKAGE (system confirmation remains required) in place of the generic ACTION_DELETE intent.
- Returns redacted playback error categories and request-stage summaries when extension video resolution fails. Error messages deliberately exclude media URLs, tokens, cookies, and authentication headers.
- Version 1.4.9-beta34.35+47.

Known limitations:
- **Not build-tested or device-tested in this environment.**
- Better Player/server-sheet presentation of errors remains limited and may still show an empty list. Inspect extension stream diagnostics in Manage Providers to see the error category and safe request summary.
- AnimeOnsen's Yūzōnō extension builds an OAuth-authenticated API client for video retrieval. This beta improves diagnosis but **does not establish** that its token exchange, video parsing or stream resolution succeeds. Avoid adding site-specific bypasses to the shared Host API without evidence.
- System uninstall may still depend on Android OEM/package-installer behavior. If the dialog does not open, capture the displayed error for the next fix.
- Existing local repositories and approved APK source metadata are preserved.

Test: launch Extensions page without manually refreshing; verify populated Browse, Installed and Updates; uninstall a test extension with system confirmation; in Manage Providers test stream resolution on AnimeOnsen, recording only status/error types and safe request stages.
