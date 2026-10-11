# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta24 — ASS playback clock and Aniyomi DEX fix
- ASS rendering now interpolates playback time with a monotonic clock between coarse player position notifications; uses Flutter display vsync and re-anchors on detected seeks, pause/play, buffering and significant drift.
- Preserves beta23 performance diagnostics and adds clockResyncs, clockSeeks and interpolatedFrames counters.
- Fixed DEX magic header validation in ExtensionDexInspector: previously compared against a literal backslash-n instead of the required newline, preventing dependency inspection.
- Explicitly reports dexInspectionStatus, superclass, interfaces, class location and scan errors, including failures.
- Retains beta22 ASS texture rendering and premultiplied-alpha native AAR; import workflow now targets beta24.
- Clock interpolation is an approximation, not direct decoder PTS synchronization. Android TV smoothness and APK build are not yet verified.

## v1.4.9-beta23 — Extension and ASS performance diagnostics
- Read DEX class definitions to inspect direct superclass/interfaces without running extension code.
- Added Flutter and native ASS performance logs for player position changes and rendering time.

## v1.4.9-beta22 — ASS vsync rendering
- Pace active ASS rendering via Flutter display vsync using video position.
- Compare DexClassLoader and PathClassLoader resolution failures.
