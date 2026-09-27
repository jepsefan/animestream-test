# v1.4.8-beta10

> Test release focused on account sync, Android TV controls, updates, and playback defaults.

## Changes since beta9

### SIMKL watched progress
- Watching progress now enters the remote sync path when SIMKL is connected, instead of falling back to local-only storage just because AniList is not logged in.
- This fixes the beta9 case where SIMKL login worked but completed/watch progress was not sent to SIMKL.

### Android TV D-pad
- D-pad center / OK is now handled in the top-level Watch focus handler.
- When the player overlay is hidden, center / OK opens it directly.
- Hidden Left / Right keep the existing seek behavior and skip animation.
- Touch and mouse control behavior remains unchanged.

### In-app beta updates
- Update checks now use releases from `jepsefan/animestream-test` instead of FrostNova's upstream repository.
- A currently installed beta automatically allows newer prerelease/beta updates even if the normal prerelease setting is off.
- The update dialog's browser link now opens the fork releases page.
- Android in-place updates still require all APKs to be signed with the same keystore.

### Playback quality
- Preferred playback quality now defaults to **1080p**.
- Existing beta installs using the old 720p default are migrated to 1080p once.
- After that migration, users can still manually choose 720p or another quality without it being forced back to 1080p.

### AniList login
- No AniList PIN/device-flow change is included in this beta.
- AniList's Auth Pin flow is different from SIMKL Device Flow and requires separate AniList OAuth client configuration.
