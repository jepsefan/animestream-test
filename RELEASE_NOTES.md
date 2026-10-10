# v1.4.9-beta2 — Android TV player recovery

Built on beta1. Failed initialization should no longer trap the Android TV Back action behind visible controls. Initialization errors now include stack traces when available, and repeated identical Better Player exception events are deduplicated in the app's player log (not suppressed in the playback engine). AniDB V1/V2/V3 HTTP diagnostics remain enabled. This is an untested fix: it does not guarantee every exit path, resolve the underlying source error, or fix the unrelated Hive box-close issue.

---

# v1.4.9-beta1 — AniDB playback experiment

Based on `v1.4.9` master. Reintroduces the AniDB V1/V2/V3 implementations and source registrations from the earlier beta30 test branch, without changing the Better Player fork or unrelated playback code. V1 uses Referer and HEAD diagnostics; V2 uses Referer, Origin and User-Agent; V3 adds a bounded HTTP Range GET probe to inspect media response status and MP4 signatures. This is a test release; AniDB playback remains unverified and may still fail.

---

# v1.4.9 Release Notes

This release is based on the `v1.4.8-beta23` application source, with version and documentation updates. It retains the subtitle/WebVTT, Android TV controls, SIMKL login/sync, AMOLED dimming, and experimental AniDB.se V1/V2/V3 features present in beta23. AniDB playback has not been confirmed working. Later beta24–beta30 code is intentionally excluded.

## v1.4.8 beta1–beta23 history

# v1.4.8-beta1

Original upstream notes: dub support for a source; retry for failed downloads; Windows/Linux playback fixes. The original notes warned that this was an experimental release.

---

# v1.4.8-beta2

- Baseline test build used for the custom BetterPlayer work.
- AnimeStream was switched to the writable **jepsefan/betterplayer-test** fork.
- BetterPlayer was pinned to a specific test commit.
- This beta did not yet include Stable Overlap, status-text positioning, or the Android TV Play/Pause changes.

Historical summary reconstructed from beta5 retrospective; original GitHub release reused beta1 notes.

### Android TV Amlogic decoder compatibility (beta2 test investigation)

On an **SDMC DV8919-KST (Telia Nordic STB, Android API 31)** using `OMX.amlogic.avc.decoder.awesome2` and Media3 `1.9.2`, migrating Better Player from Flutter `SurfaceTextureEntry` to `TextureRegistry.SurfaceProducer` correlated with a reproducible H.264 DASH playback failure at 1280×720:

| Rendering path | Required DPB | Allocated output buffers | Playback |
| --- | ---: | ---: | --- |
| SurfaceTextureEntry (working beta3 reference) | 8 | 14 | Works |
| SurfaceProducer (failing beta4 reference) | 23 | 21 | Fails |
| SurfaceProducer without `setSize()` | 23 | 21 | Fails |
| SurfaceTextureEntry restored (beta2 test build) | 8 | 14 | Works |

The failing decoder reported `Failed to provide requested picture buffers. (Got 21, requested 23)` and entered error state 2. Disabling `surfaceProducer.setSize()` alone did not fix it; fully restoring the SurfaceTextureEntry path did. The exact mechanism behind the DPB change remains unknown.

Relevant Better Player commits: last known working `54e1a2e`, SurfaceProducer migration `2849caa`, setSize-disabled test `41a12a3`, SurfaceTexture restoration `b214c1da`. AnimeStream dependency update: `563edfcd`; beta2 test build: `ab0c3aa`. This is a historical test finding, not a claim that all Amlogic devices are affected.

---

# v1.4.8-beta3

- Added the experimental **Stable Overlap** subtitle renderer.
- Added a runtime selector between **Default** and **Stable Overlap**.
- Added stable positioning for overlapping WebVTT cues.
- Added connected overlap-group handling so cues can reserve their positions for the lifetime of the group.
- Added experimental detection/left-side handling for status/UI subtitle groups with 5+ cues sharing the same start time; **left-side placement was not working correctly**.
- Fixed nullable subtitle-text handling.
- Began Android TV Play/Pause remote-control fixes.

Historical summary reconstructed from beta5 retrospective; original GitHub release reused beta1 notes.

---

# v1.4.8-beta4

- Carried forward the Stable Overlap subtitle work from beta3.
- Attempted left-side rendering for status/UI subtitle groups; **this did not work correctly in testing**.
- Attempted WebVTT continuation handling for text without repeated timestamps; **this did not work correctly in testing**.
- Made **Stable Overlap** the default subtitle renderer.
- Added further Android TV Play/Pause remote-control handling changes.
- Fixed a BetterPlayer WebVTT parser syntax error that blocked Android builds.
- Disabled Linux and Windows CI build jobs for the beta test workflow.

Historical summary reconstructed from beta5 retrospective; original GitHub release reused beta1 notes.

---

# v1.4.8-beta5

> Test release. The subtitle renderer changes are still experimental and may need further tuning on Android TV.

## v1.4.8-beta5

### Subtitle rendering
- Added the new **Stable Overlap** subtitle renderer.
- Stable Overlap is now the default subtitle renderer.
- Added a player-bar selector to switch between **Default** and **Stable Overlap** while a video is playing.
- Overlapping WebVTT cues are kept in stable positions so visible text does not jump when another cue appears or disappears.
- Connected overlapping cues are handled as one overlap group and preserve their original cue order.
- Experimental detection for status/UI subtitle groups with **5 or more cues sharing the same start time** was added in earlier betas.
- Reworked status/UI subtitles into a separate fixed left-side layer using explicit positioning.
- Fixed nullable subtitle text handling in the Stable Overlap renderer.

### WebVTT parsing
- Experimental WebVTT continuation parsing was added for text after blank lines without a repeated timestamp.
- Multi-line status cues are now rendered as one HTML block so continuation text such as **Attack / Defense / Magic / Speed** keeps its formatting and remains visible.
- Existing HTML subtitle formatting such as bold and italic text remains supported.

### Android TV controls
- Changed Android TV media-key handling so **Play/Pause** toggles playback instead of only pausing.
- Added explicit handling for **Play**, **Pause**, and **Space** playback keys.
- Moved media-key handling into the player's parent Focus tree so remote-control media keys can still be received when another player control has focus.
- Mapped Android TV **D-pad Right** to seek forward by the configured skip duration (10 seconds by default).
- Mapped Android TV **D-pad Left** to seek backward by the configured skip duration (10 seconds by default).

### Build and CI
- Includes the BetterPlayer WebVTT parser build fix introduced after beta4.
- Android-focused beta workflow; Linux and Windows CI builds remain disabled.

---

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

# v1.4.8-beta7

> Test release. This beta refines AnimeStream's subtitle pipeline and Android TV remote handling.

## v1.4.8-beta7

## Changes since beta6

### Subtitle fixes
- Removed keyword-based status/UI detection; only dense near-simultaneous cue groups are treated as status/UI now.
- VTT `\\h` spacing escapes are converted to normal spaces instead of being rendered literally.
- Removed empty lines inside parsed VTT cues so status text such as **Attack / Defense / Magic / Speed** does not consume excessive vertical space.
- Ignore ASS/SSA vector drawing commands such as `m 0 0 l 290 0 290 42 0 42` instead of displaying them as subtitle text.
- Increased status/UI cue grouping tolerance from **20 ms to 100 ms**, allowing cues such as 18:37.850 and 18:37.900 to stay in the same visual group.
- Added real configurable text alignment to `SubtitleText`; status/UI text now uses left alignment instead of being centered inside a left-positioned container.
- Increased the status/UI text area width to **62%** of the video width.

### Android TV controls
- Restored Play/Pause handling in the parent Android TV key handler.
- Keeps D-pad center/select available for navigating and activating player controls.
- Removed the old BetterPlayer **Subtitle renderer** button from AnimeStream because AnimeStream's visible subtitles are rendered by `SubViewer`, so that control was not connected to the active subtitle renderer.

---

# v1.4.8-beta8

> Test release. This beta adds safer status/UI subtitle grouping and Android TV focus navigation.

## Changes since beta7

### Subtitle status grouping
- Status/UI subtitles now use the area from 5% below the top to 5% above the bottom; oversized groups are scaled down to stay fully inside the video frame.
- Standalone status keywords such as **Attack**, **Defense**, **Magic**, **Speed**, **Equipment**, and **Skills** can identify a status/UI block.
- A keyword only triggers when it occupies a complete subtitle line by itself.
- When triggered, **all cues with the exact same start timestamp** are grouped together and rendered in the existing left-side status area.
- Embedded text such as `Monster: Raana` does not trigger this rule.

### Android TV controls
- Added a real focus target to the center **Play/Pause** control when player controls appear.
- When controls are visible, D-pad directions are left to Flutter focus navigation.
- When controls are hidden, the existing **Left/Right seek behavior and skip animation** are preserved.
- Existing Play/Pause media-key handling is unchanged.

---

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

---

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

---

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

---

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

---

# v1.4.8-beta13

> Test release focused on global AMOLED inactivity protection.

## Changes since beta12

### AMOLED inactivity dimming
- When **AMOLED Background** is enabled, the whole AnimeStream interface dims after 60 seconds without user input.
- The 60-second dimming is disabled when **AMOLED Background** is turned off.
- D-pad/key input, touch, pointer movement, hover, and scroll activity reset the timer.
- The dim layer fades in and out and does not change the device's system brightness.
- Returning to the app resets the inactivity timer.
- The player's shorter pause-specific dimming remains separate.

---

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

---

# v1.4.8-beta15

> Test release focused on Android launcher icon behavior.

## Changes since beta14

### Android launcher icon
- The purple AnimeStream icon now uses the standard adaptive launcher resource `@mipmap/ic_launcher`.
- Android can now apply the same launcher mask/shape behavior as the previous green icon.
- The purple symbol remains the foreground artwork on a black adaptive-icon background.

---

# v1.4.8-beta16

> Diagnostic test release focused on the AniList-to-SIMKL ID lookup.

## Changes since beta15

### SIMKL lookup diagnostics
- Added detailed APP-log output for the SIMKL anime search used to resolve an AniList anime to a SIMKL ID.
- Logs the AniList lookup query, HTTP status code, SIMKL response body, result count, and resolved SIMKL ID.
- Non-2xx search responses now include the HTTP status and response body in the thrown error.
- Unexpected SIMKL search response formats are logged explicitly.

### Purpose
- Helps diagnose why AnimeStream can sync AniList and MAL while SIMKL is missing from the SyncHandler list.
- Does not change the SIMKL V2 login or watch-history sync behavior.

---

# v1.4.8-beta17

> Test release fixing authenticated AniList-to-SIMKL ID lookup.

## Changes since beta16

### SIMKL authenticated lookup
- SIMKL anime search requests now include the saved SIMKL access token when available.
- SIMKL anime info requests use the same authenticated headers.
- Sends `Authorization: Bearer <token>`, `simkl-api-key`, and `Accept: application/json`.
- Keeps the beta16 lookup diagnostics so HTTP status, response data, result count, and resolved SIMKL ID remain visible in the APP log.
- Access tokens are never written to the log.

### Why
- Beta16 confirmed SIMKL returned HTTP 401 `user_token_required` because this client ID requires a user access token on every request.
- This allows the existing AnimeStream flow to resolve AniList ID -> SIMKL ID before SyncHandler updates SIMKL watch progress.

---

# v1.4.8-beta18

> Test release using MyAnimeList as the primary external-ID lookup for SIMKL.

## Changes since beta17

### MAL -> SIMKL lookup test
- When AniList is the active database, AnimeStream now reads the existing MAL ID from the AniList info result first.
- SIMKL lookup is performed with `https://myanimelist.net/anime/<malId>` instead of the AniList URL in this beta.
- The APP log explicitly shows that MAL is being used as the SIMKL lookup source.
- Logs the MAL URL, result count, and resolved SIMKL ID.
- If no MAL ID is available, the log states that the SIMKL lookup was skipped.

### Intended follow-up behavior
- Beta18 is deliberately MAL-first so the MAL -> SIMKL mapping can be tested independently.
- After this path is verified, the intended normal behavior is AniList -> SIMKL first, then MAL -> SIMKL only when the AniList lookup returns zero results.

---

# v1.4.8-beta19

> SIMKL external-ID lookup now uses AniList first with MyAnimeList as fallback.

## Changes since beta18

### AniList -> SIMKL primary lookup
- When AniList is the active database, AnimeStream first searches SIMKL using `https://anilist.co/anime/<id>`.
- The APP log explicitly shows that AniList is being used as the primary SIMKL lookup source.

### MAL -> SIMKL fallback
- If the AniList lookup succeeds but returns `results=0`, AnimeStream reads the MAL ID already provided by AniList.
- It then retries SIMKL lookup with `https://myanimelist.net/anime/<malId>`.
- The APP log shows when the fallback is triggered, the MAL URL used, the result count, and the resolved SIMKL ID.
- If no MAL ID exists, the log states that the fallback was skipped.

### Logging
- Keeps the authenticated SIMKL request diagnostics from beta16/beta17.
- Typical successful fallback sequence:
  `AniList -> SIMKL results=0`
  `AniList results=0 -> MAL fallback`
  `MAL -> SIMKL results=1`
  `resolved simklId=...`

### VTT stacked subtitle colors
- Added visual separation for overlapping VTT cues in the normal bottom subtitle stack.
- The newest/bottom cue is white.
- The cue above it is light gray (`#D0D0D0`).
- Older cues use gray (`#9E9E9E`).
- This only affects VTT cues in bottom-aligned groups; status/UI cues and ASS rendering keep their existing behavior.

---

# v1.4.8-beta20

> Subtitle cleanup and VTT overlap-color test release.

## Changes since beta19

### VTT empty-row cleanup
- VTT dialogue lines are now cleaned before they are added to a cue.
- `\\h`, repeated `\\h`, HTML/VTT tags, and surrounding whitespace are removed before deciding whether a line is empty.
- Lines that become empty after cleanup are skipped instead of creating visible blank rows.
- A second cleanup is performed when the cue is finalized, so fully empty cues are not created.
- This is intended to make the status/UI subtitle block behave consistently on mobile and Android TV.

### VTT overlapping cue colors
- Bottom-aligned VTT cues now cycle through three text colors by cue order:
  - white
  - light gray (`#D0D0D0`)
  - gray (`#9E9E9E`)
  - then repeat white -> light gray -> gray
- A single cue therefore uses white.
- This replaces the beta19 behavior where all cues older than the second one were gray.
- The color cycling only applies to normal bottom-aligned VTT cues. Status/UI cues and ASS rendering keep their existing behavior.

### SIMKL lookup
- Keeps the beta19 AniList -> SIMKL primary lookup with MAL -> SIMKL fallback when AniList returns zero results.

---

# v1.4.8-beta21

> Adds optional multi-color VTT cue styling.

## Changes since beta20

### VTT cue color cycle
- Bottom-aligned VTT cues now cycle through four colors:
  - white
  - gray (`#9E9E9E`)
  - light yellow (`#CCBF51`) with a black stroke
  - green (`#53FB57`) with a black stroke and black background
  - then repeat from white
- A single cue starts as white.
- Status/UI cues to the left are not part of this color cycle.

### Subtitle setting
- Added a new `VTT cue colors` toggle in Subtitle Settings.
- The setting is enabled by default, including for existing installs that do not yet have the saved value.
- Turning it off restores the normal configured subtitle text/stroke/background colors instead of using the cue color cycle.

### VTT cleanup
- Keeps the beta20 cleanup that removes empty, whitespace-only, tag-only, and `\\h`-only rows before they can create visible blank subtitle lines.

### SIMKL lookup
- Keeps the beta19 AniList -> SIMKL primary lookup with MAL -> SIMKL fallback when AniList returns zero results.

---

# v1.4.8-beta22

> Locks VTT cue colors so visible subtitles do not change color when another cue ends.

## Changes since beta21

### Locked VTT cue colors
- Each normal bottom-aligned VTT cue gets a color slot the first time it is shown.
- That cue keeps the same color for its lifetime, even if an older overlapping cue disappears.
- New colorized cues continue the four-color sequence instead of recalculating colors from the current visible stack.
- Status/UI cues shown on the left do not consume a color slot.

### VTT cue color cycle
- The enabled cue-color sequence remains:
  - white
  - gray (`#9E9E9E`)
  - light yellow (`#CCBF51`) with black stroke
  - green (`#53FB57`) with black stroke
  - then repeat from white
- Green no longer forces a black background.

### Subtitle setting
- Keeps the `VTT cue colors` toggle from beta21.
- It remains enabled by default.
- Turning it off restores the configured normal subtitle colors.

### VTT cleanup
- Keeps the beta20 cleanup for empty, whitespace-only, tag-only, and `\\h`-only rows.

### SIMKL lookup
- Keeps the AniList -> SIMKL primary lookup with MAL -> SIMKL fallback.

### AniDB provider
- Updated the AniDB source base URL from `https://anidb.app` to `https://anidb.se`.

---

# v1.4.8-beta23

> Experimental AniDB.se provider rebuild with three independently selectable variants.

## Changes since beta22

### AniDB.se provider variants
- Rebuilt the AniDB provider around the new `anidb.se` site structure instead of the old `anidb.app` frontend API.
- Added three separate built-in test sources so they can be compared independently:
  - `AniDB.se v1` — root-site search using `/?s=<title>`.
  - `AniDB.se v2` — `/anime/` archive search using the same `s` parameter.
  - `AniDB.se v3` — direct English-title slug lookup, for URLs such as `/anime/the-exiled-heavy-knight-knows-how-to-game-the-system/`.
- Search results now keep the full anime URL as the provider alias instead of trying to extract the old numeric AniDB.app ID.

### Episode discovery
- Anime pages are parsed for episode links directly from HTML.
- Episode numbers are detected from link text or URLs containing `episode` / `ep`.
- Provider logs now show the anime page and number of episodes detected.

### Stream discovery
- Episode pages are inspected for direct `.m3u8` URLs, common `file` / `source` script assignments, video/source tags and iframe/embed pages.
- The provider follows one level of iframe/embed pages while looking for a playable HLS stream.
- Logs show the selected variant, episode page and number of streams found.

### Safer source search
- Empty provider searches no longer cause `RangeError ... valid value range is empty: 0` from `match[0]`.
- The app now reports a normal no-results error instead, making source testing easier.

### Existing beta22 changes kept
- VTT cue colors remain locked to each cue while it is tracked.
- Green VTT cue styling has black stroke without a forced black background.
- The VTT cue-colors toggle remains enabled by default.

---

## Later experiments (not included in v1.4.9)

### v1.4.8-beta24
AniDB episode placeholder href and stream discovery experiments.

### v1.4.8-beta25
No separate published beta25 release found; development/planning notes exist.

### v1.4.8-beta26
AniDB selected-series filtering and HTTP/canonical episode verification.

### v1.4.8-beta27
AniDB episode discovery variants and validation; playback unverified.

### v1.4.8-beta28
AniDB stream extraction variants; playback unverified.

### v1.4.8-beta29
AniDB exact-series episode matching and HEAD diagnostics; playback still stalled.

### v1.4.8-beta30
AniDB header comparisons and Range GET diagnostics; playback still stalled.

