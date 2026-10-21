# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.74, beta34.73 and beta34.72.

## v1.4.9-beta34.74 — SIMKL episode artwork in existing cache
- If a source has no episode thumbnail and the user has SIMKL connected, fetch the matched SIMKL anime's episode artwork as a fallback. Original source art wins; the anime cover remains the final fallback.
- Reuse the existing CacheManager and Hive network-cache box for SIMKL episode metadata **and image bytes**. App Cache Manager controls such as Clear all cache and maximum storage size apply; no independent image cache.
- Cache successfully found episode images with long retention; do not refresh them periodically. Only missing episode numbers are retried after 24h, and failed SIMKL fetches after 30min. Fetch an anime's episode list in one request; never make one API call per missing image.
- Verify SIMKL identity via the existing alternate database ID; never guess a match solely from a title. Ignore specials and ambiguous episode numbers. Only activate when a SIMKL token is present.
- Integrate mobile list/grid and desktop/TV artwork, asynchronously so failures cannot block playback or episode listing.
- Version `1.4.9-beta34.74+84`. APK build and SIMKL live response not yet verified. README unchanged.

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

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
