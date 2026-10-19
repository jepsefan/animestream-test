# AnimeStream — Latest three beta development versions

The complete development history is in [CHANGELOG.md](CHANGELOG.md). This file covers beta34.59, beta34.58 and beta34.57; older versions remain in the changelog.

## v1.4.9-beta34.59 — Restore extension results in series pages
- The Manage Providers probe can resolve streams while the series page reports missing results because they use different source-selection paths; the probe normally omits a source ID, while the series view uses the saved approved ID.
- Forward the approved source's name and language during series-page search, episode retrieval and playback, allowing the already-implemented exact/unique identity fallback when its saved ID is stale after restart.
- Preserve existing AniList title matching, playback and subtitle handling; keep beta34.58's 20-second OLED dimming unchanged.
- Version `1.4.9-beta34.59+69`. **User-confirmed on device:** extension results now work in the series view after the source-identity change. Separate playback and pause-dimming regression checks have not yet been reported.

## v1.4.9-beta34.58 — OLED pause-dimming after 20 seconds
- Delay the existing dark OLED Pause Protection overlay from 8 seconds to 20 seconds after the video is paused.
- Keep the same overlay strength and fade animation. The dimming is cancelled on playback or buffering; no video network/startup timeouts were changed.
- Version `1.4.9-beta34.58+68`. **Build/device verification pending.**

## v1.4.9-beta34.57 — Restart-safe Source settings
- Attempt exact, unique name/language re-linking of the *already approved* extension source when its stored source ID no longer matches the installed runtime following an app restart. A missing or ambiguous match still fails safely.
- Keep source approvals, per-source preferences, APK signing/version checks, video playback and the built-in providers unchanged.
- Show an inline Saved confirmation for successful changes and a Done button in Source settings. Source-defined multi-select Save/Cancel is unchanged.
- Version `1.4.9-beta34.57+67`. **Build and device tests pending**; verify reopening AniWaves and other extensions after restart without disabling/re-enabling, and confirm persisted options and video playback.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
