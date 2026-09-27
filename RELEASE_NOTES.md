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
