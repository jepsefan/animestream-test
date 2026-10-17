# AnimeStream — Latest three beta releases

The complete development history is in [CHANGELOG.md](CHANGELOG.md). Notes below reflect the current beta34.53 development branch.

## v1.4.9-beta34.53 — Fix synthetic server labels
- Hide placeholder `no_hoster_list` and recover VidMoly-style host names from explicitly structured quality labels.
- Improve Source settings diagnostics for NoSuchMethodError with sanitized host method information. This diagnoses but does not yet establish or fix the underlying method mismatch.
- Leave playback and subtitles unchanged. **Not yet built/device-tested.**

## v1.4.9-beta34.52 — More informative video server selection
- Retain the Hoster display name for modern Anikku extensions when retrieving video streams and lazy-resolving their links.
- Show extension and hoster together in the server selector, while preserving all video tracks, HTTP headers and source quality labels.
- Episode-only sources continue using their familiar labels.
- Source settings show human-readable list choices where supported.
- **Not yet built/device-tested.** Beta34.51 source/episode recovery was user-confirmed.

## v1.4.9-beta34.51 — Recover extension episode searches
- Retry ordinary title searching after a saved extension match returns no episodes or fails, instead of repeatedly trying the stale match.
- Distinguish empty manual search results from search errors; record safe error stages for failed episode loading.
- Source settings now identify the safe error type, stage and missing classes when available.
- No changes to playback or AnimeOnsen service handling. **User-confirmed on device:** [Ext] sources that previously failed to find episodes work again in beta34.51. Individual playback hosts and source settings have not all been separately checked.

## v1.4.9-beta34.50 — More Yūzōnō settings
- Support multi-select options declared by installed Anikku extensions. Shows checkboxes and saves selected values in the source's own preferences.
- Example: AniWaves.ru can declare Exclude Servers / Exclude Types instead of requiring source-specific UI code.
- Validate every selection against the extension-provided option set; retain Cancel without saving.
- No changes to media playback or AnimeOnsen. **Not yet build/device tested.**

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
