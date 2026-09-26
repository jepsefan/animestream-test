# v1.4.8-beta6

> Test release. This beta moves the subtitle fixes into AnimeStream's actual subtitle pipeline and adds D-pad seek animation.

## v1.4.8-beta6

## Changes since beta5

### Subtitle pipeline
- Moved the status/UI subtitle implementation into AnimeStream's actual **SubViewer** renderer.
- Reworked **VttRipper** so WebVTT cues are delimited by timestamps instead of blank lines.
- Continuation text such as **Attack / Defense / Magic / Speed** now stays attached to the same timed cue.
- Status/UI subtitles are rendered in a dedicated fixed left-side layer.

### Android TV D-pad seek
- **D-pad Right** seeks forward by the configured skip duration.
- **D-pad Left** seeks backward by the configured skip duration.
- D-pad seek now uses the same on-screen animation and skip counter as double-tap seek.

---


### Subtitle rendering
- Added the new **Stable Overlap** subtitle renderer.
- Stable Overlap is now the default subtitle renderer.
- Added a player-bar selector to switch between **Default** and **Stable Overlap** while a video is playing.
- Overlapping WebVTT cues are kept in stable positions so visible text does not jump when another cue appears or disappears.
- Connected overlapping cues are handled as one overlap group and preserve their original cue order.
- Experimental detection for status/UI subtitle groups with **5 or more cues sharing the same start time** was added in earlier betas.
- Reworked status/UI subtitles in AnimeStream's actual **SubViewer** renderer into a separate fixed left-side layer using explicit positioning.
- Fixed nullable subtitle text handling in the Stable Overlap renderer.

### WebVTT parsing
- Experimental WebVTT continuation parsing was added for text after blank lines without a repeated timestamp.
- Replaced blank-line-based VTT cue splitting in AnimeStream's **VttRipper** with timestamp-based cue boundaries so continuation text such as **Attack / Defense / Magic / Speed** remains part of the timed cue.
- Existing HTML subtitle formatting such as bold and italic text remains supported.

### Android TV controls
- Changed Android TV media-key handling so **Play/Pause** toggles playback instead of only pausing.
- Added explicit handling for **Play**, **Pause**, and **Space** playback keys.
- Moved media-key handling into the player's parent Focus tree so remote-control media keys can still be received when another player control has focus.
- Mapped Android TV **D-pad Right** to seek forward by the configured skip duration (10 seconds by default).
- Mapped Android TV **D-pad Left** to seek backward by the configured skip duration (10 seconds by default).
- D-pad seek now uses the same on-screen skip animation/counter as double-tap seek.

### Build and CI
- Includes the BetterPlayer WebVTT parser build fix introduced after beta4.
- Android-focused beta workflow; Linux and Windows CI builds remain disabled.

---

## Previous betas

### v1.4.8-beta4
- Carried forward the Stable Overlap subtitle work from beta3.
- Attempted left-side rendering for status/UI subtitle groups; **this did not work correctly in testing**.
- Attempted WebVTT continuation handling for text without repeated timestamps; **this did not work correctly in testing**.
- Made **Stable Overlap** the default subtitle renderer.
- Added further Android TV Play/Pause remote-control handling changes.
- Fixed a BetterPlayer WebVTT parser syntax error that blocked Android builds.
- Disabled Linux and Windows CI build jobs for the beta test workflow.

### v1.4.8-beta3
- Added the experimental **Stable Overlap** subtitle renderer.
- Added a runtime selector between **Default** and **Stable Overlap**.
- Added stable positioning for overlapping WebVTT cues.
- Added connected overlap-group handling so cues can reserve their positions for the lifetime of the group.
- Added experimental detection/left-side handling for status/UI subtitle groups with 5+ cues sharing the same start time; **left-side placement was not working correctly**.
- Fixed nullable subtitle-text handling.
- Began Android TV Play/Pause remote-control fixes.

### v1.4.8-beta2
- Baseline test build used for the custom BetterPlayer work.
- AnimeStream was switched to the writable **jepsefan/betterplayer-test** fork.
- BetterPlayer was pinned to a specific test commit.
- This beta did not yet include Stable Overlap, status-text positioning, or the Android TV Play/Pause changes.

### Earlier v1.4.8 beta notes
The repository previously carried the original beta notes:
- Dub support for a source.
- Added retry option for failed downloads.
- Fixed playback issues on Windows/Linux.
