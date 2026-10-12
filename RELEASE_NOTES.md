# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta28 — ASS 24 FPS and Aniyomi diagnostics visibility
- Add 24 FPS to the persisted ASS Renderer frequency selector (Auto, 24, 30, 60, 120 FPS) in Player Settings → Subtitle settings.
- Include the beta27 diagnostics display fix for hostApiClassProbe, missingHostApiClassCount, dexHierarchy, dexTransitiveMissingDependencies, dexHierarchyScanErrors and dexObfuscatedSuperclassResolved in Manage Providers → Test class.
- Extension execution is not yet supported; Android build and device testing have not been performed.

## v1.4.9-beta27 — ASS frequency and Aniyomi extension runtime (in progress)
- Implemented: Player Settings → Subtitle settings → ASS Renderer frequency (Auto, 30, 60, 120 FPS), persisted in Hive; vsync remains the upper bound and the existing serialized render path is preserved.
- Implemented: non-executing Aniyomi host API class availability probe, including transitive hierarchy dependencies and missing-host-class counts. Actual Aniyomi host API compatibility/runtime execution is not implemented yet.
- Status: development branch; no Android build or device test has been performed. Extension execution remains unsupported.

## v1.4.9-beta26 — ASS playback clock continuity
- Remove the remaining 1000 ms ASS interpolation cap so animations can advance while the Android TV player reports a stale position.
- Distinguish fresh and repeated player positions; only use fresh reports to correct clock drift, while pause/buffering and seek transitions still re-anchor.
- Add freshReports/staleReports counters to ASS performance logs for beta26 validation.
- Add metadata-only Aniyomi extension superclass/interface hierarchy diagnostics, including obfuscated superclass `i`, transitive missing dependencies and hierarchy scan errors. No extension code is executed and host API support is not yet implemented.
- Keep native assrender AAR and Better Player fork unchanged.
- APK build and Android TV behavior have not yet been verified.

