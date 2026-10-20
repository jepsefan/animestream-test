# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.73, beta34.72 and beta34.71.

## v1.4.9-beta34.73 — Re:ANIME manual HLS audio switching
- Beta34.72 sound works and ASS delay Step works, but changing English/Japanese in Audio Track did not switch audible language.
- Fix wrong HLS rendition metadata after [Sub]/[Dub] sorting: audio NAME and URI now always come from the same reordered track.
- Better Player branch hls-audio-language-selection-reanime matches Media3 track labels or language metadata instead of assuming a playlist index equals the native group index, and retains deferred track selection.
- Preserve working default audio, proxy HLS playback, direct MKV and per-anime/source ASS delay Step.
- Version 1.4.9-beta34.73+83. APK compilation and device track switch have not yet been verified.

## v1.4.9-beta34.72 — Re:ANIME Sub/Dub audio selection
- Re:ANIME legitimately returns HD-1 and HD-2 Hoster entries per [Sub] and [Dub]; the HLS playlist may expose multiple language renditions within each host.
- Prefer Japanese audio as the default HLS rendition when the selected server is [Sub] and English audio when it is [Dub], if those languages exist. Preserve the original order when no matching language is available.
- Pin the paired Better Player fork `hls-audio-label-selection-reanime`: Android matches ExoPlayer audio renditions by label rather than wrongly equating HLS rendition index with renderer group index. Requests made before ExoPlayer discovers tracks are retried when tracks change.
- Preserve external ASS timing editor with 0.05/0.5/1s step, per-anime/per-provider delay isolation, HLS proxy, subtitles and MKV entry.
- Version `1.4.9-beta34.72+82`. APK build and on-device audio switching not yet verified; server content and language labels may differ.

## v1.4.9-beta34.71 — Adjustable external ASS delay step
- Add a **Step** button at the far left of the in-player external ASS sync toolbar. Each tap cycles the +/- increment through 0.05 s → 0.50 s → 1.00 s → 0.05 s.
- Minus and plus apply the selected step immediately. The signed total delay and Reset/Done remain unchanged, and the saved offset stays isolated by anime and video provider. The step itself resets to 0.05 s per player session.
- Focus the Step control first on Android TV and exclude obscured playback controls from keyboard navigation during editing.
- Existing audio, HLS proxy, subtitle renderer and extension handling unchanged; README unchanged.
- Version `1.4.9-beta34.71+81`. APK compilation/device behavior not yet verified.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
