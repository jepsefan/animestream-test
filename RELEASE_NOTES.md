# AnimeStream — Latest three beta development versions

The complete development history is in [CHANGELOG.md](CHANGELOG.md). Notes cover beta34.58, beta34.57 and beta34.56; older releases are in the changelog.

## v1.4.9-beta34.58 — OLED pause-dimming after 20 seconds
- Delay the existing dark OLED Pause Protection overlay from 8 seconds to 20 seconds after the video is paused.
- Keep the same overlay strength and fade animation. The dimming is cancelled on playback or buffering; no video network/startup timeouts were changed.
- Version `1.4.9-beta34.58+68`. **Build/device verification pending.**

## v1.4.9-beta34.57 — Restart-safe Source settings
- Attempt exact, unique name/language re-linking of the *already approved* extension source when its stored source ID no longer matches the installed runtime following an app restart. A missing or ambiguous match still fails safely.
- Keep source approvals, per-source preferences, APK signing/version checks, video playback and the built-in providers unchanged.
- Show an inline Saved confirmation for successful changes and a Done button in Source settings. Source-defined multi-select Save/Cancel is unchanged.
- Version `1.4.9-beta34.57+67`. **Build and device tests pending**; verify reopening AniWaves and other extensions after restart without disabling/re-enabling, and confirm persisted options and video playback.

## v1.4.9-beta34.56 — Source Settings AndroidX Preference linkage
- Preserve AndroidX Preference classes and JVM methods in R8-minified APKs. Installed Anikku/Aniyomi extensions reference these APIs dynamically.
- The beta34.55 AniWaves.ru [Ext] Source settings test failed at `settings_build_screen` with `NoSuchMethodError: getContext` in `AniWaves.setupPreferenceScreen`. Upstream source calls `screen.context` to create preferences; this fix targets the likely missing/renamed host method.
- Existing Source settings UI already supports source-declared lists, multiple-choice lists and toggles. This beta does not hardcode AniWaves options or modify the playback/player/subtitle code.
- Version `1.4.9-beta34.56+66`. **Device-tested:** AniWaves.ru [Ext] settings opens with ten options; the prior `getContext` failure is no longer observed. Settings save immediately without a global confirmation button. **Remaining issue:** after closing, reopening settings may return `settings_load_source / IllegalStateException (invalid_source_state)` until extension sources are refreshed/re-enabled; the precise affected source needs confirmation. Persistence after restart and unrelated extension playback not verified for this build.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
