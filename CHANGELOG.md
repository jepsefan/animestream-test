# Changelog

## v1.4.9

Promoted from the `v1.4.8-beta23` source baseline. The application changes tested in beta24–beta30 are **not included**. See `RELEASE_NOTES.md` for full beta history and known limitations.

## v1.4.8 beta history

### v1.4.8-beta1
See release notes for details.

### v1.4.8-beta2
BetterPlayer test fork baseline. Android TV playback compatibility: reverting Better Player's SurfaceProducer migration to SurfaceTextureEntry restored H.264 playback on SDMC DV8919-KST (Amlogic). In 1280×720 tests, SurfaceProducer requested 23 DPB buffers but received 21 and failed; SurfaceTextureEntry requested 8 with 14 allocated and worked. Fix: Better Player `b214c1da` (reported A/B/A tests).

### v1.4.8-beta3
Experimental Stable Overlap subtitle renderer and Android TV media-key work.

### v1.4.8-beta4
Further subtitle and TV-control experiments; some subtitle changes did not work correctly.

### v1.4.8-beta5
Added the new **Stable Overlap** subtitle renderer.; Stable Overlap is now the default subtitle renderer.; Added a player-bar selector to switch between **Default** and **Stable Overlap** while a video is playing.

### v1.4.8-beta6
Moved the status/UI subtitle implementation into AnimeStream's actual **SubViewer** renderer.; Reworked **VttRipper** so WebVTT cues are delimited by timestamps instead of blank lines.; Continuation text such as **Attack / Defense / Magic / Speed** now stays attached to the same timed cue.

### v1.4.8-beta7
Removed keyword-based status/UI detection; only dense near-simultaneous cue groups are treated as status/UI now.; VTT `\\h` spacing escapes are converted to normal spaces instead of being rendered literally.; Removed empty lines inside parsed VTT cues so status text such as **Attack / Defense / Magic / Speed** does not consume excessive vertical space.

### v1.4.8-beta8
Status/UI subtitles now use the area from 5% below the top to 5% above the bottom; oversized groups are scaled down to stay fully inside the video frame.; Standalone status keywords such as **Attack**, **Defense**, **Magic**, **Speed**, **Equipment**, and **Skills** can identify a status/UI block.; A keyword only triggers when it occupies a complete subtitle line by itself.

### v1.4.8-beta9
Added SIMKL device authorization using `POST /oauth2/device`.; The account page shows the returned `user_code` and verification URL.; Added an **Open Simkl** button using `verification_uri_complete` when available.

### v1.4.8-beta10
Watching progress now enters the remote sync path when SIMKL is connected, instead of falling back to local-only storage just because AniList is not logged in.; This fixes the beta9 case where SIMKL login worked but completed/watch progress was not sent to SIMKL.; D-pad center / OK is now handled in the top-level Watch focus handler.

### v1.4.8-beta11
The fork now uses Android application ID `app.animestream.test`.; It can be installed alongside the normal AnimeStream app instead of Android treating it as an update to `app.animestream`.; SIMKL device login now validates the returned access token before reporting a successful login.

### v1.4.8-beta12
Fixed the post-login validation request to use GET for `/users/settings`.; Fixed the normal SIMKL profile request to use GET for `/users/settings`.; This addresses the 403 error shown after approving the SIMKL PIN login even though SIMKL had already returned an access token.

### v1.4.8-beta13
When **AMOLED Background** is enabled, the whole AnimeStream interface dims after 60 seconds without user input.; The 60-second dimming is disabled when **AMOLED Background** is turned off.; D-pad/key input, touch, pointer movement, hover, and scroll activity reset the timer.

### v1.4.8-beta14
When **AMOLED Background** is enabled, AnimeStream dims after 60 seconds without input.; The 60-second global dimming is disabled while the full-screen player page is open.; The player's own pause-specific OLED dimming remains separate.

### v1.4.8-beta15
The purple AnimeStream icon now uses the standard adaptive launcher resource `@mipmap/ic_launcher`.; Android can now apply the same launcher mask/shape behavior as the previous green icon.; The purple symbol remains the foreground artwork on a black adaptive-icon background.

### v1.4.8-beta16
Added detailed APP-log output for the SIMKL anime search used to resolve an AniList anime to a SIMKL ID.; Logs the AniList lookup query, HTTP status code, SIMKL response body, result count, and resolved SIMKL ID.; Non-2xx search responses now include the HTTP status and response body in the thrown error.

### v1.4.8-beta17
SIMKL anime search requests now include the saved SIMKL access token when available.; SIMKL anime info requests use the same authenticated headers.; Sends `Authorization: Bearer <token>`, `simkl-api-key`, and `Accept: application/json`.

### v1.4.8-beta18
When AniList is the active database, AnimeStream now reads the existing MAL ID from the AniList info result first.; SIMKL lookup is performed with `https://myanimelist.net/anime/<malId>` instead of the AniList URL in this beta.; The APP log explicitly shows that MAL is being used as the SIMKL lookup source.

### v1.4.8-beta19
When AniList is the active database, AnimeStream first searches SIMKL using `https://anilist.co/anime/<id>`.; The APP log explicitly shows that AniList is being used as the primary SIMKL lookup source.; If the AniList lookup succeeds but returns `results=0`, AnimeStream reads the MAL ID already provided by AniList.

### v1.4.8-beta20
VTT dialogue lines are now cleaned before they are added to a cue.; `\\h`, repeated `\\h`, HTML/VTT tags, and surrounding whitespace are removed before deciding whether a line is empty.; Lines that become empty after cleanup are skipped instead of creating visible blank rows.

### v1.4.8-beta21
Bottom-aligned VTT cues now cycle through four colors:; A single cue starts as white.; Status/UI cues to the left are not part of this color cycle.

### v1.4.8-beta22
Each normal bottom-aligned VTT cue gets a color slot the first time it is shown.; That cue keeps the same color for its lifetime, even if an older overlapping cue disappears.; New colorized cues continue the four-color sequence instead of recalculating colors from the current visible stack.

### v1.4.8-beta23
Rebuilt the AniDB provider around the new `anidb.se` site structure instead of the old `anidb.app` frontend API.; Added three separate built-in test sources so they can be compared independently:; Search results now keep the full anime URL as the provider alias instead of trying to extract the old numeric AniDB.app ID.

### v1.4.8-beta24 (excluded from v1.4.9)
AniDB episode placeholder href and stream discovery experiments.

### v1.4.8-beta25 (excluded from v1.4.9)
No separate published beta25 release found; development/planning notes exist.

### v1.4.8-beta26 (excluded from v1.4.9)
AniDB selected-series filtering and HTTP/canonical episode verification.

### v1.4.8-beta27 (excluded from v1.4.9)
AniDB episode discovery variants and validation; playback unverified.

### v1.4.8-beta28 (excluded from v1.4.9)
AniDB stream extraction variants; playback unverified.

### v1.4.8-beta29 (excluded from v1.4.9)
AniDB exact-series episode matching and HEAD diagnostics; playback still stalled.

### v1.4.8-beta30 (excluded from v1.4.9)
AniDB header comparisons and Range GET diagnostics; playback still stalled.

