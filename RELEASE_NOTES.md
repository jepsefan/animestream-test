# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.84, beta34.83 and beta34.82.

## v1.4.9-beta34.84 — Unified audio tracks and Android TV Back behavior
- Removed the duplicate **External HLS audio** choice that restarted the video. Both HLS and MKV now use the actual tracks reported by the active Media3/ExoPlayer player, selected directly without reopening playback.
- Show readable audio languages (Japanese, English, etc.) in a single list; hide synthetic HLS suffixes such as `Native_1` and `English_2`. Keep the underlying track identifiers intact for playback.
- Android TV: pressing Back when the playback controls overlay is visible hides it instead of immediately leaving playback. Press Back again with the controls hidden to leave the player. On phones, touching the video toggles the controls; system Back no longer stops at the player overlay.
- The existing beta34.83 English-first extension subtitle preference remains unchanged.
- Version `1.4.9-beta34.84+94`. Not yet compiled or device-verified.

## v1.4.9-beta34.83 — Default extension subtitles and selectable Re:ANIME audio
- Added **Player → External ASS Subtitles → Default source subtitle language** (English by default, with Auto and other language choices). This is separate from the existing Preferred ASS Language used by cross-source ASS lookup. Native extension subtitles now prefer the chosen language when available, otherwise retain the source's first subtitle.
- Added a shared audio picker in the mobile and desktop/TV controls. Android Better Player now queries the current ExoPlayer/Media3 player for actual embedded audio tracks, including MKV, and can select a validated renderer/group/track without assuming HLS metadata.
- For extension-provided external HLS audio, selecting a rendition regenerates the local HLS master with that track as default, reopens the same video and seeks back to the prior position; restores playing/paused state. Stream URLs and headers are never displayed in the menu.
- Pointed AnimeStream to the compatible Better Player fork branch `hls-mkv-embedded-audio-track-selection`. Existing subtitle renderer, extension API and metadata functionality remain unchanged.
- Version `1.4.9-beta34.83+93`. **Not Flutter/Gradle compiled or verified on Android hardware.** A provider exposing audio metadata does not guarantee the remote stream has independently playable HLS audio.

## v1.4.9-beta34.82 — Extension details recovery and Anikku season API
- Added the Anikku `getSeasonList(SAnime)` Host API signature with an unsupported default, preserving older extensions and leaving existing episode numbering untouched. This is ABI groundwork; the app does not automatically merge seasons yet.
- Added a version-neutral `getAnimeDetails` bridge (modern suspend API, legacy Rx fallback only when unsupported).
- When an approved extension returns zero episodes or its first episode request fails, retry once using that extension's updated series details and source URL. Successful episode requests are unchanged, and the original error is retained if recovery also fails.
- Episode results report `detailsFallbackUsed` and `detailsFallbackStage` for testing, without exposing credentials or introducing extra calls for functioning sources.
- Retain beta34.80 full episode lists, beta34.81 completed-cover shading, APK approvals, stream handling, audio, ASS subtitles and SIMKL as before.
- Version `1.4.9-beta34.82+92`. Android/Flutter build and device tests have not been run.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
