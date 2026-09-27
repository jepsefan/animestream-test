# v1.4.8-beta12

> Test release focused on fixing SIMKL login validation.

## Changes since beta11

### SIMKL login
- Fixed the post-login validation request to use GET for `/users/settings`.
- Fixed the normal SIMKL profile request to use GET for `/users/settings`.
- This addresses the 403 error shown after approving the SIMKL PIN login even though SIMKL had already returned an access token.

### Included from beta11
- Separate Android application ID `app.animestream.test` for parallel installation.
- SIMKL QR/PIN login.
- OLED pause dimming after 8 seconds.
- Android TV info-page focus improvements.
- AniList local-network QR login remains available.
