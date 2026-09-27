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

### UI defaults
- AMOLED Background is now enabled by default.
- Existing beta installs using the old default are migrated to AMOLED once.
- Users can still turn AMOLED Background off manually afterwards.

### Playback quality
- Preferred playback quality now defaults to **1080p**.
- Existing beta installs using the old 720p default are migrated to 1080p once.
- After that migration, users can still manually choose 720p or another quality without it being forced back to 1080p.

### AniList TV login
- Android TV now offers a local-network QR login option for AniList.
- The QR code opens a temporary HTTP page hosted directly by the TV on its LAN IP.
- The phone opens AniList Auth Pin login, then the returned access token can be pasted into the local page and sent directly to the TV.
- The QR code contains only the TV's temporary local login URL and session ID, never the AniList token itself.
- The TV validates the received token before saving it.
- Android TV also keeps a **Use old login** option for the existing redirect-based flow.
- Phones and tablets continue to use the existing AniList login flow directly without showing the QR screen.
- This requires a separate `ANILIST_PIN_CLIENT_ID` whose AniList Redirect URL is `https://anilist.co/api/v2/oauth/pin`.
