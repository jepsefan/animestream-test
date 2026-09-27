# v1.4.8-beta9

> Test release. This beta adds SIMKL PIN/device-code login.

## Changes since beta8

### SIMKL login
- Added SIMKL device authorization using `POST /oauth2/device`.
- The account page shows the returned `user_code` and verification URL.
- Added an **Open Simkl** button using `verification_uri_complete` when available.
- The app polls `POST /oauth2/token` until authorization succeeds or the device code expires.
- Handles `authorization_pending`, `slow_down`, `expired_token`, and `access_denied`.
- The device flow uses `SIMKL_CLIENT_ID` and does not use the redirect URL flow for SIMKL login.
- Device authorization requests now use form-style OAuth parameters instead of JSON bodies.
- Cancel now stops the polling loop instead of leaving it running in the background.
- Expired device codes automatically request a new code.
- SIMKL device-flow errors are shown with specific messages and a retry option in the PIN dialog.
- Android TV D-pad directions no longer open the player overlay while it is hidden; Left/Right keep the existing ±skip seek, while D-pad center/OK opens the overlay.
