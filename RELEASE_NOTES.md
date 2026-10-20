# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.70, beta34.69 and beta34.68.

## v1.4.9-beta34.70 — In-player external ASS sync and audio tracks
- Store subtitle timing offset for *cross-source ASS only*, separately per anime **and active video provider** (e.g. Re:ANIME and Animegg have independent offsets). All episodes within the same anime/provider share one delay; old anime-only delay values are intentionally not migrated. A positive delay shows the text later, and a negative delay shows it sooner, in 50 ms steps.
- When an external ASS track is active, the subtitle menu offers **Edit sub delay**. It closes the subtitle sheet, leaves the ASS visible and shows a top-of-player edit strip with minus, signed time, plus, Reset and Done. Existing controls are hidden during editing; Back exits the editor.
- Apply the offset to libass's rendering clock without modifying the original subtitle file, video position, original ASS/VTT streams or the HLS/audio pipeline.
- Display extension-provided HLS AUDIO renditions in the mobile and TV/desktop audio selectors when the legacy HLS parser returns no list (including Re:ANIME loopback proxy paths). Prevent crashes when the player reports no native HLS audio tracks.
- Keep working KickAssAnime audio, Re:ANIME API support and beta34.69 proxy handling; README unchanged.
- Version `1.4.9-beta34.70+80`. APK compilation and device playback have not yet been verified.

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

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
