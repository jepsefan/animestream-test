# AnimeStream — Latest three beta releases

The complete development history is in [CHANGELOG.md](CHANGELOG.md). Notes below reflect the current beta34.49 development branch.

## v1.4.9-beta34.49 — Manual matches and source images
- Save user-confirmed extension title matches after successfully loading episodes, in both manual search dialogs.
- Prefer episode preview artwork, then extension cover artwork, then AniList cover in supported episode tiles.
- Preserve existing verified playback pipeline and known deferred subtitle issue.
- Build and device testing pending.

## v1.4.9-beta34.48 — Activate all installed extensions
- Add one **Enable all installed sources** button in Manage Providers [Beta], requiring confirmation that lists the installed APKs to enable.
- Skip already-approved sources, activate remaining extensions one at a time, and show progress plus per-extension failure summaries.
- Keep signature/version validation, persisted source approvals, existing playback, and explicit trust consent unchanged.
- Update outdated explanation in provider management.
- **Not yet build/device tested.** Beta34.47 playback was user-confirmed.

## v1.4.9-beta34.47 — Lazy video links
- Add fallback from Anikku's modern `resolveVideo` to older `getVideoUrl` for compatible extension-hosted video placeholders.
- Preserve audio/subtitle tracks and headers; don't issue extra requests for already playable URLs.
- AnimeOnsen search fallback, built-in providers and subtitle renderer unchanged.
- Build/device regression testing required.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
