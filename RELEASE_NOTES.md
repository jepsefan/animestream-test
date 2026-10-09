# v1.4.8-beta26

> AniDB.se episode-selection fix on the full beta24 baseline.

## Changes since beta24
- Retains beta24's code and Android test package ID (`app.animestream.test`).
- Limits AniDB.se episode links to the selected anime, addressing wrong-series playback observed in beta25.
- Checks episode HTTP responses and canonical URLs, skipping 404 and mismatched pages.
- Requires video/embed elements or recognizable media URLs before adding an episode.
- Adds diagnostic logs for skipped and verified episodes.

## Known limitations
- Build and playback have not yet been verified.
- Embedded players without detectable video links may still be missed.
- Search-result matching may need further correction after testing.

## Version
- `1.4.8-beta26+1`

# v1.4.8-beta24

> Fixes AniDB.se episode targets that were resolving to `https://anidb.se#`.

## Changes since beta23

### AniDB.se episode links
- Keeps the three AniDB.se test sources: `v1`, `v2`, and `v3`.
- Episode discovery now checks normal links plus common `data-*` attributes and `onclick` URLs.
- If an episode control only uses `href="#"`, the provider now keeps the anime page and attaches the episode number internally instead of turning it into `https://anidb.se#`.
- Also checks inline scripts for common episode-number + URL object layouts.

### AniDB.se stream discovery
- When an episode is a same-page selector, the provider first inspects the matching episode element and nearby parent containers.
- Looks there for:
  - direct `.m3u8` links
  - embed/player URLs
  - iframe/embed/video/source elements
- Then falls back to the existing whole-page and one-level iframe scan.
- Added compact diagnostics showing how many stream candidates were found for the requested episode.

### Version
- Updated to `1.4.8-beta24+1`.
