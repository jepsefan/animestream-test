# Beta11 assrender integration — corrected architecture

## Confirmed current behavior
In `lib/ui/pages/watch.dart`, `Player(controller)` and `SubViewer(...)` are sibling widgets in a Flutter `Stack`.
`lib/ui/models/widgets/subtitles/subViewer.dart` loads external subtitles using AnimeStream's own `Subtitleparsers` and synchronizes cues against `VideoController.position`.
Therefore external ASS subtitles are rendered by AnimeStream, not by Better Player.

## Correct integration target
Keep Better Player and its existing video playback path unchanged.
Keep AnimeStream's `SubViewer` for VTT/SRT and existing Stable Overlap behavior.
For ASS/SSA, add an opt-in native libass renderer exposed to Flutter as a bitmap/texture or platform-view overlay, synchronized with `VideoController.position` and respecting seeking and pause.

## Compatibility caveat
The fork `jepsefan/assrender` is currently designed around Media3/ExoPlayer extraction:
`AssHandler`, `AssRenderersFactory`, `AssExtractorsFactory`, and `SubtitleOverlayView`.
These cannot simply be dropped into AnimeStream's Flutter `SubViewer`.
We must first inspect/reuse its native libass bridge and support external ASS files directly, rather than requiring a second ExoPlayer instance or modifying Better Player.

## Next code steps
1. Identify native libass API and font/bitmap output in assrender.
2. Add a Flutter-to-Android interface for loading an external ASS/SSA file, viewport sizing and rendering at a given timestamp.
3. Present the bitmap overlay in the same `Stack` as `SubViewer`; do not display two subtitle renderers simultaneously.
4. Preserve VTT/SRT path, player controls, Android TV key behavior, and subtitle settings.
5. Verify release APK, arm64/armv7, subtitle synchronization, overlapping cues, and no playback regressions.

Status: Native libass script loading has been added to jepsefan/assrender (nativeLoadScript). An Android MethodChannel handler skeleton exists in ExternalAssRenderer.kt on beta11. It is NOT registered in MainActivity and assrender AAR is NOT added as a Gradle dependency, so it is intentionally not yet compiled or usable. Flutter ExternalAssOverlay.dart prototype now exists with URL/local file loading, a 100ms position polling loop, PNG frame display and generation guards. Still NOT wired into watch.dart or registered in MainActivity; the AAR is not available as an app dependency. Next: package AAR with native .so files, wire channel and choose ASS-only overlay with safe fallback, test builds and performance. PNG-per-frame is only a prototype transport and must be optimized before release.

## AAR build preparation (2026-10-10)
An AAR build workflow was committed to jepsefan/assrender at `.github/workflows/build-aar.yml` for arm64-v8a and armeabi-v7a. This workflow is unverified. The existing CMake configuration still expects FFmpeg, fontconfig and expat shared libraries; the existing libass build script disables fontconfig, so native dependency compatibility must be resolved before claiming a successful AAR. The AnimeStream Gradle dependency, channel registration and watch.dart switch remain intentionally pending until a valid AAR is available.

## Native build simplification
The assrender fork now has `ASSRENDER_ENABLE_FFMPEG=OFF` by default. The CMake target uses only `ass_direct.c` and `ass_direct_jni.c` and links libass/Freetype/FriBidi/HarfBuzz. The AAR workflow builds libass for both Android ABIs without invoking the FFmpeg build script. Font provider selection changed to `ASS_FONTPROVIDER_AUTODETECT`. These changes are committed but have NOT been compiled or verified in GitHub Actions. AnimeStream channel registration and Gradle dependency are still pending a valid AAR.

## Beta11 AAR integration update
The Android MethodChannel is registered in MainActivity.kt, and watch.dart now selects ExternalAssOverlay for Android ASS while retaining SubViewer for VTT/SRT. The Android app Gradle dependency expects `android/app/libs/assrender-release.aar`. A manual GitHub Actions workflow `.github/workflows/import-assrender-aar.yml` downloads the latest successful assrender AAR artifact from `jepsefan/assrender` and commits it to this beta11 branch. **This workflow has not been run or validated yet.** Run it under AnimeStream Actions (requires cross-repo artifact read permission and workflow contents:write permission), then verify that the AAR appears in the branch. Only then build/test APK. Note that PNG over MethodChannel at 100ms is a performance prototype, and native fallback handling still needs work.
