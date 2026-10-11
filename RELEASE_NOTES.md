# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta20 — ASS 50 ms and corrected AAR import (test)
- Keep the native ASS Texture render polling interval at **50 ms** for comparison on Android TV.
- Import workflow now targets the beta20 AnimeStream branch and downloads the latest successful assrender AAR built on `beta19-alpha-compositing`.
- The corrected native alpha blending only reaches the APK **after** the AAR is rebuilt/imported and the APK is rebuilt.
- Aniyomi extension diagnostics now check both declared source classes and factory classes against DEX, list matching candidates, and report whether the failing dependency appears in the scanned DEX. Execution remains unsupported.
- Better Player remains unchanged.

## v1.4.9-beta19 — ASS alpha experiment and extension diagnostics
- Changed ASS render polling to 50 ms.
- Prepared native alpha compositing fix in the separate assrender repository.
- Extension class loading remains experimental.

## v1.4.9-beta18 — Texture overlay and extension diagnostics
- Android SurfaceTexture / Flutter Texture ASS overlay.
- Centered 16:9 subtitle viewport and class loading diagnostics.

## Test status
Beta20 is not confirmed built or device-tested. The import workflow must be run before the APK build.
