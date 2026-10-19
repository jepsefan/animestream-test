# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.64, beta34.63 and beta34.62.

## v1.4.9-beta34.64 — Mobile Ext sub / built-in ASS providers
- Place **Ext sub** toggle in the actual mobile Episodes header; keep the desktop/TV toggle. Per-anime setting controls automatic external ASS lookup.
- Add AnimeOnsen, AniZone, Anikoto and Animegg as global Primary/Secondary source choices beside approved extensions. Support both legacy built-in subtitle URLs and extension subtitle tracks, with strict ASS verification and selected language filtering.
- Preserve working beta34.63 HLS external audio behavior, episode art and Discover behavior.
- Version `1.4.9-beta34.64+74`; no APK or device verification yet.

## v1.4.9-beta34.63 — HLS external audio / ASS from another extension
- Experimental HLS audio bridge: present the selected extension video and its external audio rendition(s) to Android's native player using a local-only HLS master playlist; do not change the original remote media URLs. Video falls back to its original link if bridge preparation fails.
- Under Player Settings, configure Primary ASS Source, Secondary ASS Source and language. On each anime's Episodes page, **Ext sub** enables automatic cross-source ASS lookup. The last successfully used source for that anime is remembered.
- Strict unique show/episode matching or an already-confirmed saved source alias. Search is asynchronous and does not block startup; matching failures leave normal subtitles available. Player subtitle menu offers manual Primary/Secondary lookups.
- **Build fix:** Move the HLS manifest bridge `dispose()` override to the `PlayerProvider` `ChangeNotifier`; it had been placed in `PlayerProviderState` and caused two Dart compiler errors. APK rebuild pending.
- **Android lint fix:** Add missing `includeSubdomains="false"` attributes to the loopback-only network security config, resolving the reported `lintVitalRelease` failures. Rebuild pending.
- Version `1.4.9-beta34.63+73`. **Not yet successfully APK-built or tested on device**; no guarantee that all HLS variants, ASS services and source-specific headers are compatible.

## v1.4.9-beta34.62 — Extension episode artwork
- Load and show the episode's own `preview_url` image, when provided, in both image-based episode layouts.
- Resolve relative preview URLs against the installed extension's base domain; reject unsupported schemes. Fallback order is episode preview, source series cover, AniList cover, neutral placeholder.
- Keep series matching, streaming, subtitles, Discover counts and beta34.61's rollback of Manual Search Pagination unchanged.
- Version `1.4.9-beta34.62+72`. **Build/device validation pending**.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
