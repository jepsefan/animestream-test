# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.63, beta34.62 and beta34.61.

## v1.4.9-beta34.63 — HLS external audio / ASS from another extension
- Experimental HLS audio bridge: present the selected extension video and its external audio rendition(s) to Android's native player using a local-only HLS master playlist; do not change the original remote media URLs. Video falls back to its original link if bridge preparation fails.
- Under Player Settings, configure Primary ASS Source, Secondary ASS Source and language. On each anime's Episodes page, **Ext sub** enables automatic cross-source ASS lookup. The last successfully used source for that anime is remembered.
- Strict unique show/episode matching or an already-confirmed saved source alias. Search is asynchronous and does not block startup; matching failures leave normal subtitles available. Player subtitle menu offers manual Primary/Secondary lookups.
- Version `1.4.9-beta34.63+73`. **Not yet APK-built or tested on device**; no guarantee that all HLS variants, ASS services and source-specific headers are compatible.

## v1.4.9-beta34.62 — Extension episode artwork
- Load and show the episode's own `preview_url` image, when provided, in both image-based episode layouts.
- Resolve relative preview URLs against the installed extension's base domain; reject unsupported schemes. Fallback order is episode preview, source series cover, AniList cover, neutral placeholder.
- Keep series matching, streaming, subtitles, Discover counts and beta34.61's rollback of Manual Search Pagination unchanged.
- Version `1.4.9-beta34.62+72`. **Build/device validation pending**.

## v1.4.9-beta34.61 — More titles in Discover
- Double the requested **Recently Updated** schedules (25 → 50) and **Recommended** entries (25 → 50). Filtering, duplicates and AniList availability can reduce the final number of visible cards.
- Expand **This Season** from 40 to up to 80 results using two AniList pages while leaving Home / Aired This Season unchanged at 40.
- Reset Discover lists on refresh to avoid accumulated duplicates. Manual Search Pagination has been rolled back to beta34.59; playback behavior is retained.
- Version `1.4.9-beta34.61+71`. **Build/device validation pending.**

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
