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
