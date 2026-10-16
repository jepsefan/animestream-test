# beta34.43 — Anikku audio/subtitle track metadata

Based directly on beta34.42, the user-confirmed working reference for AnimeOnsen and Animenosub.

- The playback-only bridge now preserves the language, label, and URL of up to 24 external audio tracks, without displaying URLs or secrets in diagnostics.
- Adds ExternalAudioTrack and VideoStream.externalAudioTracks with map serialization for Dart.
- Keeps the already-working external subtitle handling unchanged, and shows counts of external subtitle/audio tracks in server selection.
- The Better Player internal/HLS audio selector is unchanged. External standalone audio URLs **are not yet selectable/playable**; metadata is not treated as an automatically supported audio track.
- No site-specific parsing or special-case extension changes.
- Version 1.4.9-beta34.43+54.

**Not built or device tested here.** Build APK, verify that AnimeOnsen and Animenosub playback still works, and check server selections. If a source provides external audio, the server card should show an external audio count (metadata only).
