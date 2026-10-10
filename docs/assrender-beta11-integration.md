# Beta11: assrender integration (work in progress)

## Verified repositories
- assrender fork: https://github.com/jepsefan/assrender
- Better Player fork: https://github.com/jepsefan/betterplayer-test (subtitle-renderer-test)
- AnimeStream branch: v1.4.9-beta11-assrender-test

## Technical compatibility
assrender's README describes `AssHandler`, `AssRenderersFactory`,
`AssExtractorsFactory` and `SubtitleOverlayView`.
Its Gradle build uses Media3 1.5.1 (compileOnly), while Better Player uses
Media3 1.8.0. Do not add an untested AAR to the app: API compatibility and
transitive native dependencies must be validated first.

Better Player creates `ExoPlayer.Builder(context)` inside
`android/src/main/kotlin/com/jhomlala/better_player/BetterPlayer.kt`
and renders video to a Flutter `SurfaceTexture`. The assrender example
assumes control of the ExoPlayer factory and a native Android overlay View.
Adding only the assrender dependency does not enable ASS rendering.

## Required implementation steps
1. Build the assrender fork as an Android AAR, or publish it to a resolvable
   Maven repository; verify arm64-v8a and armeabi-v7a native libraries.
2. Adapt its Media3 API to 1.8.0 and compile against the Better Player fork.
3. In BetterPlayer.kt, opt in to AssRenderersFactory/AssExtractorsFactory
   without affecting existing HLS/DASH/DRM and caching paths.
4. Bridge ASS bitmaps into Flutter's video widget overlay (or use an
   Android PlatformView); a native SubtitleOverlayView alone will not
   automatically appear over the Flutter texture.
5. Expose a renderer toggle through Better Player's Flutter controller;
   keep existing Stable Overlap VTT behavior unchanged.
6. Support external ASS files as well as embedded ASS tracks; assrender's
   extractor path is primarily for embedded tracks.
7. Test Android TV seeking, playback speed, track switching, PiP,
   overlapping subtitles, and release builds.

## Current status
Planning only. Beta11 is NOT yet an assrender-enabled APK.
