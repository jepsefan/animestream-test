# v1.4.8-beta5

> Test release. The subtitle renderer changes are still experimental and may need further tuning on Android TV.

## Subtitle rendering

- Added the new **Stable Overlap** subtitle renderer.
- Stable Overlap is now the default subtitle renderer.
- Added a player-bar selector to switch between **Default** and **Stable Overlap** while a video is playing.
- Overlapping WebVTT cues are kept in stable positions so visible text does not jump when another cue appears or disappears.
- Connected overlapping cues are handled as one overlap group and preserve their original cue order.
- Added separate handling for status/UI subtitle groups with **5 or more cues sharing the same start time**.
- Status/UI groups are rendered on the left side of the picture instead of in the normal centered dialogue area.
- Added a dedicated left-side layout so status text does not expand back toward the center.
- Fixed nullable subtitle text handling in the Stable Overlap renderer.

## WebVTT parsing

- Improved WebVTT parsing for subtitle files where text continues after blank lines without repeating the timestamp.
- Continuation text now stays attached to the preceding timed cue until the next timestamp begins.
- This preserves multi-part status text such as **Attack / Defense / Magic / Speed** that previously lost lines because the continuation blocks had no timestamps of their own.
- Preserved existing HTML subtitle formatting such as bold and italic text.

## Android TV controls

- Changed Android TV media-key handling so **Play/Pause** toggles playback instead of only pausing.
- Added explicit handling for **Play**, **Pause**, and **Space** playback keys.
- Moved media-key handling into the player's parent Focus tree so remote-control media keys can still be received when another player control has focus.

## Build and CI fixes

- Fixed a BetterPlayer WebVTT parser syntax error that prevented Android release builds.
- Disabled Linux and Windows build jobs in the beta test workflow.
- The beta workflow now focuses on Android builds only.
