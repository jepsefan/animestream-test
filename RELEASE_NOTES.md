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

