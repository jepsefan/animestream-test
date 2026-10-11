# AnimeStream v1.4.9 — latest beta release notes

Only the current beta and two previous betas are shown here. Earlier versions are archived in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta19 — ASS alpha and extension diagnostics (test build)
- Target a 50 ms native ASS texture render poll interval (up to 20 updates per second).
- Native libass alpha source-over fix is committed in assrender branch `beta19-alpha-compositing`; **not included in the APK until a new AAR is built and imported**.
- Preserve beta18 ASS positions and Texture-based overlay.
- Carry forward experimental Aniyomi APK class diagnostics; extension execution is not yet supported. Further class/DEX diagnosis is pending.
- Better Player unchanged.

## v1.4.9-beta18 — ASS texture and extension diagnostics
- Native Android SurfaceTexture and Flutter Texture rendering instead of per-frame PNG transfer.
- Centered 16:9 ASS texture overlay.
- Additional extension class-loading exception and APK path diagnostics.

## v1.4.9-beta17 — Aniyomi class-loading diagnostics
- DEX candidate scanning and root-cause exception reporting.
- ASS transparency differences relative to beta16 reported during device testing.

## Status
Beta19 is **not built or verified**. Its native alpha fix needs a rebuilt AAR and the extension class-loader changes still need implementation.
