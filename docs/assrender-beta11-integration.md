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

Status: design corrected; native integration is not yet implemented or build-tested.
