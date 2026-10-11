# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta21 — Extension class loading diagnostics
- Display complete Android Aniyomi extension class diagnostics in Manage Providers, including manifest entry points, DEX inventory, declared/target class presence, dependency class presence, exception chain and root cause.
- Adaptive ASS texture polling: 16 ms during detected ASS animation cues, 50 ms for static active cues, and 200 ms when no cue is active. Rendering uses the player's current position; this is not yet synchronized to individual decoded video frames.
- Native assrender source on `beta19-alpha-compositing` now composites libass colors in premultiplied RGBA for Android ARGB_8888 bitmaps, including overlapping layers. This color correction requires a freshly built and imported AAR and is not yet device-verified.
- Import workflow targets beta21 and pulls the latest successful assrender AAR from `beta19-alpha-compositing`; run the native AAR build after the color fix before importing.
- Extensions remain diagnostic only, not executable as playable sources.

## v1.4.9-beta20 — ASS 50 ms and corrected AAR integration
- Kept ASS texture polling at 50 ms and fixed Kotlin bridge to call nativeRender(Boolean).
- Added extension class/factory DEX diagnostics (previously not fully shown in UI).

## v1.4.9-beta19 — ASS alpha experiment
- Introduced 50 ms ASS polling and native alpha compositing work in assrender.

## Test status
Beta21 changes are committed but APK build and device tests are not verified.
