# AnimeStream — Latest three beta releases

The complete development history is in [CHANGELOG.md](CHANGELOG.md). Notes below reflect the current beta34.51 development branch.

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
