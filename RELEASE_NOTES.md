# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta30 — ASS motion smoothing controls and Aniyomi compatibility (in progress)
- Add persisted player-bar dropdown: Motion Smoothing Av / Automatisk positionsinterpolering.
- IMPORTANT: motion interpolation rendering is not yet implemented; the control currently stores the requested mode only, and does not change the ASS texture motion.
- Next Aniyomi work: implement binary-compatible AnimeSource, AnimeCatalogueSource, AnimeHttpSource and ConfigurableAnimeSource plus required dependencies before class loading and instantiation can succeed. No runtime compatibility layer has been implemented yet.
- No APK build or device test performed.

## v1.4.9-beta29 — Aniyomi host API compatibility (in progress)
- Start implementing binary-compatible Aniyomi host API support for third-party extensions, beginning with ConfigurableAnimeSource and AnimeHttpSource identified in beta28.
- Add an ASS FPS popup in the in-player control bar: Auto plus 1–30 FPS, with live updates to the active overlay and persisted selection. The existing 24/30/60/120 FPS Player Settings selector remains available.
- Preserve beta28 ASS settings and diagnostics.
- Host API runtime integration, class instantiation, and playback are not implemented or verified yet. Do not treat this branch as a working extension release.

## v1.4.9-beta28 — ASS 24 FPS and Aniyomi diagnostics visibility
- Add 24 FPS to the persisted ASS Renderer frequency selector (Auto, 24, 30, 60, 120 FPS) in Player Settings → Subtitle settings.
- Include the beta27 diagnostics display fix for hostApiClassProbe, missingHostApiClassCount, dexHierarchy, dexTransitiveMissingDependencies, dexHierarchyScanErrors and dexObfuscatedSuperclassResolved in Manage Providers → Test class.
- Extension execution is not yet supported; Android build and device testing have not been performed.

