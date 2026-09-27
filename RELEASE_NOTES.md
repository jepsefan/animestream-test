# v1.4.8-beta11

> Test release focused on parallel installation, SIMKL login, and OLED pause protection.

## Changes since beta10

### Separate Android test app
- The fork now uses Android application ID `app.animestream.test`.
- It can be installed alongside the normal AnimeStream app instead of Android treating it as an update to `app.animestream`.

### SIMKL login
- SIMKL device login now validates the returned access token before reporting a successful login.
- SIMKL profile parsing accepts the alternate user ID locations returned by different API responses.
- SIMKL sync operations are now awaited so sync failures are no longer detached from the caller.
- The SIMKL login dialog now shows a QR code.
- The QR target includes the PIN, using SIMKL's complete verification URL when supplied and `https://simkl.com/pin/<PIN>` as the fallback.
- Manual PIN entry and the Open Simkl button remain available.

### OLED pause protection
- When playback has been paused continuously for 8 seconds, a dark overlay fades over the video.
- The player controls stay above the dimming layer and remain readable.
- The dimming is removed immediately when playback resumes.
- This does not change the device's system brightness.

### MAL
- No MAL QR/device-flow change is included in beta11.
- The existing MAL login remains the browser-based OAuth2/PKCE flow.
