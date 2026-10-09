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
