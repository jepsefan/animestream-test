# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.72, beta34.71 and beta34.70.

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

## v1.4.9-beta34.70 — In-player external ASS sync and audio tracks
- Store subtitle timing offset for *cross-source ASS only*, separately per anime **and active video provider** (e.g. Re:ANIME and Animegg have independent offsets). All episodes within the same anime/provider share one delay; old anime-only delay values are intentionally not migrated. A positive delay shows the text later, and a negative delay shows it sooner, in 50 ms steps.
- When an external ASS track is active, the subtitle menu offers **Edit sub delay**. It closes the subtitle sheet, leaves the ASS visible and shows a top-of-player edit strip with minus, signed time, plus, Reset and Done. Existing controls are hidden during editing; Back exits the editor.
- Apply the offset to libass's rendering clock without modifying the original subtitle file, video position, original ASS/VTT streams or the HLS/audio pipeline.
- Display extension-provided HLS AUDIO renditions in the mobile and TV/desktop audio selectors when the legacy HLS parser returns no list (including Re:ANIME loopback proxy paths). Prevent crashes when the player reports no native HLS audio tracks.
- Keep working KickAssAnime audio, Re:ANIME API support and beta34.69 proxy handling; README unchanged.
- Version `1.4.9-beta34.70+80`. APK compilation and device playback have not yet been verified.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
