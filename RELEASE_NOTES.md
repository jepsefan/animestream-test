# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.69, beta34.68 and beta34.67.

## v1.4.9-beta34.69 — Re:ANIME local proxy HLS external audio
- Re:ANIME now returns four playable candidates, with two external audio tracks on each HLS video variant and a separate direct 1080p MKV candidate.
- Fix HLS external audio manifest wrapping for the known Re:ANIME FlixCloud loopback proxy URL shape `127.0.0.1:<port>/proxy?url=...&w_payload=...`. The proxy serves HLS but its path lacks `.m3u8`; older detection bypassed the audio bridge and played silent video.
- Keep the fallback narrow: ordinary HTTP files, including direct MKV, are not wrapped, and existing `.m3u8` HLS sources such as KickAssAnime are unaffected.
- Prevent manual quality selection from bypassing the synthesized HLS master/audio renditions. Choose a different video quality via the server picker rather than raw-variant quality overrides.
- Preserve working Hoster/Video source-api ABI, external ASS and earlier features. README unchanged.
- Version `1.4.9-beta34.69+79`. No successful APK build or device verification yet. Re:ANIME proxy audio playback and native track selection need testing.

## v1.4.9-beta34.68 — Re:ANIME Video JVM ABI
- Beta34.67 successfully passed Hoster construction and exposed a new getVideoList failure: Video Kotlin default-arguments constructor was missing.
- Align primary Video with Anikku's 14-field constructor including mpvArgs, ffmpegStreamArgs, ffmpegVideoArgs; regenerate compatible Kotlin default-mask constructor and copy semantics.
- Retain older 12-field Video constructor/copy signatures, legacy URL-first overloads, and videoPageUrl storage. Keep video/audio/subtitle metadata intact through native video resolution.
- Hoster ABI fix, HLS audio, external ASS, and other providers unchanged.
- Version `1.4.9-beta34.68+78`. APK build/device tests not yet verified.

## v1.4.9-beta34.67 — Re:ANIME Hoster constructor ABI compatibility
- Resolve the exact beta34.66 failure: Re:ANIME requires Kotlin Hoster(String, String, List, String, boolean, int, DefaultConstructorMarker). Add the upstream-compatible five-field primary Hoster constructor with lazy support.
- Retain an older four-field constructor, including its Kotlin default-arguments mask overload, for already-compiled extensions. Preserve optional legacy six-field compatibility and both copy shapes.
- Keep HLS audio, external ASS and all earlier source/Discover changes.
- Version `1.4.9-beta34.67+77`. Flutter APK build and device playback not yet verified; any additional missing Host API method will need its own targeted correction.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
