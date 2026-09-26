# v1.4.8-beta8

> Test release. This beta adds safer status/UI subtitle grouping and Android TV focus navigation.

## Changes since beta7

### Subtitle status grouping
- Standalone status keywords such as **Attack**, **Defense**, **Magic**, **Speed**, **Equipment**, and **Skills** can identify a status/UI block.
- A keyword only triggers when it occupies a complete subtitle line by itself.
- When triggered, **all cues with the exact same start timestamp** are grouped together and rendered in the existing left-side status area.
- Embedded text such as `Monster: Raana` does not trigger this rule.

### Android TV controls
- Added a real focus target to the center **Play/Pause** control when player controls appear.
- When controls are visible, D-pad directions are left to Flutter focus navigation.
- When controls are hidden, the existing **Left/Right seek behavior and skip animation** are preserved.
- Existing Play/Pause media-key handling is unchanged.
