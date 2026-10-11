# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta23 — Aniyomi DEX dependency diagnostics
- Parse installed Aniyomi extension APK DEX metadata directly (including classes2.dex and split APKs) to identify the entry class's direct superclass and interfaces without loading or executing extension code.
- Report direct superclass/interfaces, class location, and non-platform direct dependencies absent from the scanned extension DEX inventory. These are candidates, not definitive missing runtime dependencies.
- Retain beta22 PathClassLoader vs DexClassLoader diagnostics and ASS vsync rendering.
- Added 5-second ASS performance logs: Flutter vsync ticks, unique/repeated video positions, skipped ticks while rendering, MethodChannel round-trip timings and longest frame gap.
- Added native ASS performance logs: libass render time, Canvas/SurfaceTexture draw time, and actual completed native frames per second.
- Logs use `[ASSRENDER][PERF]` and `[PERF_NATIVE]` to distinguish player-clock limitations from native rendering bottlenecks; no new AAR is needed.
- Import workflow targets beta23 and keeps the premultiplied-alpha assrender AAR source branch.

## v1.4.9-beta22 — ASS display-vsync rendering
- ASS render requests paced by Flutter display vsync for active cues, using current video playback position; not decoder frame PTS synchronization.
- Compare DexClassLoader and PathClassLoader diagnostic class resolution.

## v1.4.9-beta21 — ASS alpha and extension diagnostics
- Expanded Aniyomi extension class diagnostics.
- Native premultiplied-alpha color fix via assrender AAR; requires imported updated build.

## Test status
Beta23 changes committed; APK build and Android device testing not yet verified.
