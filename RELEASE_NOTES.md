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
