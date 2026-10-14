# v1.4.9-beta34.25 — Shared extension host API (phase 1)

Branched from beta34.24, preserving the existing player, built-in sources, and local repository trust settings.

## Implemented
- `ExtensionHostRuntime.kt`: shared APK classloading, Injekt registration and factory/source instantiation in one location.
- `AnimeSourceFactory.kt`: type contract for multi-source APK factories.
- `ExtensionSourceCalls.kt`: modern suspend API with legacy RxJava fallback for searches, episode lists and direct videos. Modern `getHosterList(episode)` and `getVideoList(hoster)` are used when implemented.
- `ExtensionSearchProbe.kt` and `ExtensionEpisodeProbe.kt` now call that common runtime instead of maintaining independent extension loaders.

## Compatibility limitations
- **Not yet full Anikku source-api ABI.** The local AnimeSource/AnimeCatalogueSource/Video/Hoster models are still incomplete and may not match every APK's bytecode. A successful compilation is not proof of general extension compatibility.
- When an APK exposes multiple sources, the runtime discovers them but currently chooses its first source for the existing Flutter provider, pending per-source IDs/selection in the Flutter bridge.
- The hoster API assumes that the source implements the modern suspend methods and can supply required runtime dependencies. Older extensions use the legacy Rx fallback.
- The existing 123Anime-specific rewrite/diagnostics still exist in the older shim. They should be removed after validating generic operation.
- APK certificate validation is not yet enforced for installed extensions by this runtime. Run only explicitly trusted installed APKs.
- No build or Android TV execution test was available in this environment.

## Next phase
- Bring source-api Kotlin ABI and supporting libraries into alignment with an audited, pinned Anikku source-api version.
- Use stable `sourceId` routing for multi-source APKs through Flutter MethodChannel and provider IDs.
- Perform ABI, source-search, episodes, hosters, stream, subtitles, and playback test matrix on representative Yūzōnō extensions.
- Keep user-supplied repository URLs local; never hard-code Yūzōnō.
