# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta22 — ASS animation frame pacing
- Replaced ASS animation tag heuristics and periodic 16/50/200 ms timer with Flutter display-vsync ticker for active ASS cues.
- Passes actual video playback position to libass each active display tick, allowing all ASS transforms and frame-by-frame scripted positions to be evaluated, not only detected motion tags.
- Polls idle/empty cue intervals less frequently (about 150 ms); redraw requests remain serialized to avoid piling up native calls.
- Preserves native premultiplied-alpha color fix from assrender `beta19-alpha-compositing`; existing AAR import workflow retargeted to beta22.
- This is display-vsync paced, **not** true decoder presentation timestamp synchronization; smoothness on Android TV is unverified.

## v1.4.9-beta21 — Extension diagnostics and ASS alpha
- Expanded Aniyomi extension DEX/class loader diagnostics.
- Adaptive ASS 16/50/200 ms timer (superseded by beta22 vsync pacing).
- Native assrender premultiplied-alpha fix; requires rebuilt AAR.

## v1.4.9-beta20 — ASS integration
- Fixed Kotlin nativeRender Boolean bridge and ASS texture integration.
- Added Aniyomi extension DEX diagnostics.

## Test status
Beta22 code changes committed; APK build and device testing not yet verified.
