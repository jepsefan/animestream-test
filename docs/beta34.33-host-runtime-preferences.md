# Beta34.33 — Shared Host runtime and source preferences

Based on beta34.32 (preserves Installer / Installed / Updates / Browse / Uninstall UI).

Implemented:
- Replace the unsupported `ConfigurableAnimeSource.getSourcePreferences()` stub with source-ID-scoped Android SharedPreferences, matching Anikku's default behavior.
- Add legacy `sourcePreferences()` helpers for extension compatibility.
- Cache discovered source instances per installed package in `ExtensionHostRuntime`. Search, episode and video operations reuse stateful source objects instead of recreating them on every call.
- Invalidate the cache when Android's installed package versionCode, lastUpdateTime or APK path list changes. Uninstalled packages cannot be reloaded via PackageManager.
- Version `1.4.9-beta34.33+45`.

Caveats: This is incremental Host API parity, **not** a full port of Anikku's dependencies or preferences UI. Installation/signer pinning and explicit approvals from prior betas remain as-is. The new cache is in-memory and is cleared on process restart. No Flutter/Gradle/device build was run for beta34.33. Testing against representative installed Yūzōnō source APKs is required before considering the behavior validated.

Suggested test: build APK; install a trusted extension; approve its sources; configure a source through an extension-defined preferences screen when supported; search, open episodes and resolve streams repeatedly, then restart and verify the persisted settings. Compare any failures with Anikku's API rather than adding per-site exceptions.
