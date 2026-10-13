## v1.4.9-beta34 — Aniyomi extension search probe (unverified)
- Added an opt-in `Test search` field and confirmation dialog to Manage Providers for installed Aniyomi APKs.
- Added Flutter MethodChannel `testExtensionSearch` and an Android background-thread probe that attempts `fetchSearchAnime` through the isolated classloader.
- Search diagnostics return up to 20 titles, source URLs and cover URLs, or an error. The search operation has a 25-second wait limit.
- This is a diagnostic only: AniList remains the primary metadata source. No episode loading, stream playback or automatic matching is enabled.
- **Not yet build-verified or device-tested.** The partial Aniyomi Host API and filter ABI may still need changes.

## v1.4.9-beta33.4 — Kotlin runtime and extension instantiation
- Added release keep rules for Kotlin runtime and coroutines classes used dynamically by Aniyomi APKs.
- User-provided Beta 33.4 diagnostics showed successful instance creation for 123Anime and AnimeOnsen; search and playback were not tested.

## v1.4.9-beta33.3 — Kotlin class visibility diagnostics
- Added Kotlin stdlib dependency and host/isolated classloader probes for Function0, Intrinsics, Unit and Continuation.
- User testing showed missing Kotlin runtime classes in release, motivating Beta 33.4.

## v1.4.9-beta33.2 — Manual instantiation test
- Added explicit instantiation diagnostics and UI confirmation; no automatic extension execution.
- User testing showed NoClassDefFoundError for Kotlin Function0.

## v1.4.9-beta33.1 — ABI diagnostics
- Fixed diagnostic ordering so constructor and AnimeSource compatibility information is shown.
- User testing confirmed class loading and parameterless constructors for 123Anime and AnimeOnsen.

## v1.4.9-beta32 — Isolated class loading diagnostics
- Introduced and refined isolated child-first class loading and DEX/superclass diagnostics.
- User testing showed successful class resolution, resolving earlier final-superclass verification conflicts.

# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta31 — Aniyomi Host API scaffolding (partial)
- Enabled explicit ProGuard/R8 keep rules for dynamically referenced Host API and networking classes in release APKs.
- Added hostApiMethodProbe for selected JVM method signatures without executing extension code. This is a diagnostic probe, not ABI certification.
- Added first-pass Kotlin source contracts for AnimeSource, AnimeCatalogueSource and ConfigurableAnimeSource, plus minimal placeholder model types. These are NOT verified binary compatible and cannot yet execute extensions.
- Expanded SAnime and SEpisode model interfaces with upstream fields, companion create() factories, concrete implementations, and update/fetch enums. Added kotlinx-serialization JSON dependency. Still not binary ABI tested.
- Added an initial AnimeHttpSource HTTP/RxJava bridge for legacy popular/search/latest/detail/episode request-and-parse hooks. This is partial and not binary-compatibility verified.
- Complete model field/method ABI, network host/injection, preference storage, newer API hooks, and real class instantiation remain unimplemented. Do not use this as a working extension runtime.
- Added a third non-initializing class-resolution test using Android's installed-package context classloader, in addition to DexClassLoader and PathClassLoader.
- Added Android runtime dependencies RxJava 1, OkHttp, Jsoup, AndroidX Preference and Kotlin coroutines; their integration is not build-verified.
- Added hostApiMissingClassNames and hostApiReadinessStatus so missing dependencies can be read directly.
- Added a wider requiredHostApiProbe, requiredHostApiMissingCount and hostApiRuntimeReady to inspect required source models, networking and dependency-injection classes.
- Added packageContextClassLoaderResult to extension diagnostics. This may reveal whether package/split class paths explain class-load failures; it does not supply missing Aniyomi Host API classes.
- Reviewed upstream Aniyomi AnimeSource, AnimeCatalogueSource, ConfigurableAnimeSource and AnimeHttpSource APIs. They require additional model, RxJava, coroutine, OkHttp and dependency-injection types. Binary-compatible host API implementation and extension instantiation are NOT yet complete.
- No APK build or device testing performed.

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

