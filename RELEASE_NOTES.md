# v1.4.8-beta14

> Test release focused on Android TV navigation, AMOLED protection, SIMKL V2 permissions, and updated app branding.

## Changes since beta13

### Global AMOLED inactivity dimming
- When **AMOLED Background** is enabled, AnimeStream dims after 60 seconds without input.
- The 60-second global dimming is disabled while the full-screen player page is open.
- The player's own pause-specific OLED dimming remains separate.
- Keyboard/D-pad, touch, pointer movement, hover, and scroll reset the inactivity timer.

### Android TV player timeline
- The timeline no longer gives D-pad focus directly to the Slider widget.
- A dedicated focus wrapper now handles TV navigation while keeping the timeline glow visible.
- Left / Right seek while the timeline is focused.
- Down moves focus to the lower player controls such as quality, servers, episode list, speed, subtitles, and audio.
- Up moves focus back to the center Play/Pause control.

### SIMKL Auth V2
- SIMKL device authorization now requests both `media:read` and `media:write`.
- This allows the V2 authorization flow to request permission to update the user's media library.
- When SIMKL returns a scope field with the token response, AnimeStream checks that `media:write` was granted.
- Token validation and profile loading continue to use the authenticated SIMKL account.

### Android TV launcher
- Added Android TV Leanback launcher support.
- The app now uses a dedicated purple/magenta AnimeStream banner for the Android TV launcher tile.
- The TV banner remains separate from the mobile launcher icon.

### Mobile app icon
- The Android mobile launcher icon now uses the purple/magenta AnimeStream symbol without the wordmark.
- The adaptive icon uses a black background with the purple symbol.
- The Android TV banner remains unchanged and continues to use the wide branded tile.
