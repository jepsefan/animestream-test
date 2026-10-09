# v1.4.8-beta26

## AniDB.se fixes
- Based on the full beta24 codebase, preserving the existing Android test package ID `app.animestream.test` and prior player/subtitle changes.
- Restricts AniDB.se episode discovery to the selected anime's episode links, avoiding unrelated series.
- Checks episode HTTP status and canonical paths before listing episodes.
- Skips missing, mismatched or inaccessible episode pages without aborting the whole list.
- Requires recognizable video/embed content on an episode page.
- Adds logs for skipped and verified episodes.
- Version: `1.4.8-beta26+1`.

**Status:** Not yet build- or playback-tested. The beta25 log showed incorrect cross-series playback.

# V1.4.8-Beta1

NOTE: This is an alpha version with name of beta version. The features introduced or are modified may be buggy, install only if you dont mind dealing with them bugs!

## Whats New

- Dub support for a source
- Added retry option for failed downloads

## Fixes

- Fixed playback issues in windows/linux
