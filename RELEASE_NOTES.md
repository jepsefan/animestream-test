# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.65, beta34.64 and beta34.63.

## v1.4.9-beta34.65 — Re:ANIME Hoster and DNS diagnostics
- For installed modern extensions declaring getHosterList, do not silently fall back to legacy episode getVideoList when the modern call fails; show the real hoster-list failure stage.
- Report the hostname of DNS lookup failures observed by the shared OkHttp client during an explicitly requested stream test. Do not expose full URLs, paths, headers, tokens or cookies.
- Distinguish hoster-list failures, hoster-video-list failures and legacy episode-video-list failures in Stream test results.
- Preserve beta34.64 mobile Ext sub, inbuilt subtitle providers and working beta34.63 separate HLS audio. README unchanged.
- Version `1.4.9-beta34.65+75`. Not yet APK built or tested on device; further Re:ANIME API and host compatibility work may be needed.

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

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
