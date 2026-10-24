# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.85, beta34.84 and beta34.83.

## v1.4.9-beta34.85 — Extension episode identity and selection safety
- Extension Episode 0 ordering: explicitly numbered Episode 0 is placed before ordinary episodes even if Animenosub returns it last. Recognize explicit `Ep. 0` names or `episode-0` URLs if an extension reports a conflicting list index; other specials keep their ordering and streams keep their original URLs. Added regression tests.
- Tracker safety: progress now uses the actual regular episode number, not list index + 1. Episode 0/specials do not advance AniList, MAL or SIMKL; replaying an earlier episode does not downgrade progress. Continue buttons, resume timestamps and watched indicators use canonical episode IDs, with special resume keys separated. Added unit tests for episode-zero progress behavior.
- AniZone: distinguish regular /1–/12 episodes from /s1 specials. Guardian Fitz (Mushoku Tensei II 2023) is shown as Episode 0 before Episode 1 based on its verified source identity; other specials keep their source-defined position and do not shift regular episode numbers. Unit tests added.
- Explicit episode number 0 displays as `Episode 0` instead of being classified as unknown; missing numbers retain their source title. Fixed the parser source formatting.
- Preserve the actual episode number supplied by each approved extension; never silently replace a missing/invalid number with the position in the list.
- Keep decimal episodes and unnumbered specials labeled distinctly instead of rounding them to a potentially wrong canonical episode number. Sorting keeps their source-defined positions and uses stable numeric ordering within consecutive regular episodes.
- Episode grid and compact views show source episode identities; watch, context-menu and download actions resolve the original global list index even after pagination or filtering.
- Add Flutter unit coverage for One Piece episode 1000, decimal 1000.5, and unnumbered specials.
- Keep beta34.84 player audio switching, Android TV controls, 123Anime and existing extension search unchanged. The actual content of One Piece episode 1000 still needs user verification.
- Version `1.4.9-beta34.85+96`. APK build/device tests not run.

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

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
