# AnimeStream — Latest three beta releases

The complete development history is in [CHANGELOG.md](CHANGELOG.md). Notes below reflect the current beta34.47 development branch.

## v1.4.9-beta34.47 — Lazy video links
- Add fallback from Anikku's modern `resolveVideo` to older `getVideoUrl` for compatible extension-hosted video placeholders.
- Preserve audio/subtitle tracks and headers; don't issue extra requests for already playable URLs.
- AnimeOnsen search fallback, built-in providers and subtitle renderer unchanged.
- Build/device regression testing required.

## v1.4.9-beta34.46 — Anikku Hoster compatibility
- Add common Hoster request and parser entry points for compatible Anikku extensions.
- Support legacy per-video URL retrieval methods without changing existing playable streams.
- Legacy extensions continue using their episode-based video extraction, without additional hoster HTTP requests.
- Beta34.45 fallback search and current subtitle/player handling unchanged. **Build and playback confirmed by user.**

## v1.4.9-beta34.45 — AnimeOnsen extension search fallback
- If the extension search returns HTTP 403 from AnimeOnsen's search host, use the working built-in AnimeOnsen search API for title discovery.
- Continue loading episodes, video and subtitles through AnimeOnsen [Ext].
- The user confirmed this fallback works on device.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
