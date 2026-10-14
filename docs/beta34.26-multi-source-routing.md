# AnimeStream 1.4.9-beta34.26: Multi-source APK routing (prototype)

Base: beta34.25 shared host runtime.

- The native extension runtime can enumerate source IDs, names and languages for multiple `AnimeSource` instances returned by one extension factory.
- Android MethodChannel now exposes `discoverExtensionSources` and forwards the optional 64-bit `sourceId` to search, episode and stream resolution.
- Dart's `AniyomiExtensionProvider` binds to a specific source ID. IDs follow `aniyomi:<packageName>#<sourceId>` for unique provider selection.
- Settings -> Manage Providers allows explicitly enabling sources from an installed APK (with a consent dialog). Enabled sources appear individually in AnimeStream's source list.
- No Yūzōnō repository is baked into source.
- Built-in providers, player and subtitle rendering are unchanged.

**Limitations / security**

- This is an incremental compatibility implementation, NOT full Anikku API parity and NOT a validated APK installer.
- Source activation is intentionally **in-memory only**. After restarting AnimeStream, users must enable their trusted extension sources again; no third-party extension constructor is executed automatically on startup.
- The old single-source selection and developer diagnostics still default to the first source when no source ID is supplied.
- Running third-party extensions currently relies on the user's explicit trust decision. The runtime does not yet verify installed APK signing certificates against repository-pinned hashes. APK installation remains disabled.
- No Flutter/Gradle build, device, or Android TV tests were run from this environment. Check GitHub Actions before considering this branch usable.

**Next work:** device build verification; add certificate-validated persistent approvals and source-scoped diagnostic UI; replace incomplete source-api models with version-pinned Anikku-compatible ABI; remove temporary source-specific web workarounds after compatibility tests.
