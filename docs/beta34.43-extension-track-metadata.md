# beta34.43 — Anikku audio/subtitle track metadata

Based directly on beta34.42, the user-confirmed working reference for AnimeOnsen and Animenosub.

- The playback-only bridge now preserves the language, label, and URL of up to 24 external audio tracks, without displaying URLs or secrets in diagnostics.
- Adds ExternalAudioTrack and VideoStream.externalAudioTracks with map serialization for Dart.
- Keeps the already-working external subtitle handling unchanged, and shows counts of external subtitle/audio tracks in server selection.
- The Better Player internal/HLS audio selector is unchanged. External standalone audio URLs **are not yet selectable/playable**; metadata is not treated as an automatically supported audio track.
- No site-specific parsing or special-case extension changes.
- Version 1.4.9-beta34.43+54.

**Known issue — deferred:** In beta34.43 AnimeOnsen subtitles, one language (possibly Arabic; not confirmed) renders as squares containing crosses instead of readable characters. This may be a missing-glyph/font fallback problem, but that cause is not verified. User requested to log the issue and leave rendering unchanged for now.

**Validation:** The user reports beta34.43 plays video using AnimeOnsen [Ext] and displays **9 subtitle tracks**. The nine tracks are discovered by the UI; their individual rendering and language selection were not confirmed. Animenosub playback on this beta and external audio track availability/selection have not been separately tested. No independent build/device verification was performed in the development environment.
