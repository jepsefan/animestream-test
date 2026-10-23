# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.83, beta34.82 and beta34.81.

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

## v1.4.9-beta34.81 — Shade completed anime covers
- Give anime posters a subtle 40% black overlay when the signed-in user's **AniList watch-list status is COMPLETED**, independent of the anime's airing/release status. Leave all other statuses visually unchanged.
- Apply the reusable shading layer to normal and extended cards across Home, Discover, Search and My Lists; include Discover's trending poster and **Related / Recommended** anime covers on the series page. The opened series' own main cover/banner remains unshaded.
- Fetch completed AniList IDs as a single list request (not one request per poster), share a short-lived in-memory cache, and reuse the existing My Lists response when available. Unknown/failed status queries leave covers unchanged; fallback-only negative metadata IDs are not guessed.
- Refresh the shading immediately after successful tracking status updates and clear stored completed IDs on AniList logout; keep streaming extensions, audio, subtitles and SIMKL unchanged.
- Version `1.4.9-beta34.81+91`. Flutter compilation and device verification are pending.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
