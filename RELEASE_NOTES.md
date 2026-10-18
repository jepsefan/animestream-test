# AnimeStream — Latest three beta development versions

The complete development history is in [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.56, beta34.55 and beta34.54. Beta34.54 was an unsuccessful build-fix attempt.

## v1.4.9-beta34.56 — Source Settings AndroidX Preference linkage
- Preserve AndroidX Preference classes and JVM methods in R8-minified APKs. Installed Anikku/Aniyomi extensions reference these APIs dynamically.
- The beta34.55 AniWaves.ru [Ext] Source settings test failed at `settings_build_screen` with `NoSuchMethodError: getContext` in `AniWaves.setupPreferenceScreen`. Upstream source calls `screen.context` to create preferences; this fix targets the likely missing/renamed host method.
- Existing Source settings UI already supports source-declared lists, multiple-choice lists and toggles. This beta does not hardcode AniWaves options or modify the playback/player/subtitle code.
- Version `1.4.9-beta34.56+66`. **Device-tested:** AniWaves.ru [Ext] settings opens with ten options; the prior `getContext` failure is no longer observed. Settings save immediately without a global confirmation button. **Remaining issue:** after closing, reopening settings may return `settings_load_source / IllegalStateException (invalid_source_state)` until extension sources are refreshed/re-enabled; the precise affected source needs confirmation. Persistence after restart and unrelated extension playback not verified for this build.

## v1.4.9-beta34.55 — Fix Dart compilation of Aniyomi hoster labels
- Restore a complete Dart `RegExp` for structured quality/hoster labels and correct the interrupted `getStreams()` implementation.
- Remove accidentally duplicated Dart code outside the provider class; this addresses the reported compilation cascade in `aniyomiExtensionProvider.dart`, `sources.dart` and `infoProvider.dart`.
- Preserve meaningful server/hoster names, video quality, URLs, request headers and subtitle/audio track metadata. Continue excluding placeholder `no_hoster_list`.
- Version `1.4.9-beta34.55+65`. **User-confirmed on device:** AniWaves.ru [Ext] finds the title, lists DatSaV (360p/480p) and Vidplay (720p), and plays video successfully. This verifies the tested extension playback path; other hosts and settings remain untested, and CI build status has not been checked independently.

## v1.4.9-beta34.54 — Build-fix attempts (not successful)
- Beta34.54 development branches still contained the truncated regex and duplicate trailing code, and are superseded by beta34.55.
- **Not a verified build/release.** Use the beta34.55 correction branch instead.


### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
