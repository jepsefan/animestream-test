# v1.4.8-beta14

> Test release focused on Android TV player navigation and AMOLED protection.

## Changes since beta13

### Global AMOLED inactivity dimming
- When **AMOLED Background** is enabled, AnimeStream dims after 60 seconds without input.
- The 60-second global dimming is disabled while the full-screen player page is open.
- The player's own pause-specific OLED dimming remains separate.
- Keyboard/D-pad, touch, pointer movement, hover, and scroll reset the inactivity timer.

### Android TV player timeline
- The timeline itself no longer receives D-pad focus directly; a dedicated focus wrapper owns TV navigation.
- Left / Right seek while the timeline is focused.
- Down moves focus to the lower player controls such as quality, servers, episode list, speed, subtitles, and audio.
- Up moves focus back to the center Play/Pause control.
- The timeline focus glow remains visible.

### SIMKL Auth V2
- No scope change is included in this build yet.
- To update a SIMKL library with Auth V2, the authorization request must include the write scope in addition to read access.
