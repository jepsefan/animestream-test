# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.86, beta34.85 and beta34.84.

## v1.4.9-beta34.86 — Extension source settings
- Added an off-by-default global 18+ content switch at the bottom of Metadata in Built-in providers. It hides APKs officially marked NSFW in the source picker and guards stream access. On change, it synchronizes unambiguously named on/off adult settings from approved extension sources only. Incompatible sources are skipped; no invented extension settings or changes to AniList/MAL/SIMKL tracking.
- Source settings gear added directly to Manage Providers > Installed and the nested Installed extension catalog, including apps installed outside catalogs. Available now defaults to Installed when APK extensions exist and Browse otherwise; manual tab choice is respected.
- Installed extensions now have a Source settings page exposing their actual Aniyomi/Anikku preference options: list, on/off, multiple choice, and non-sensitive text fields for source domains.
- Preferences are stored locally per extension source and cached source instances are refreshed after saving; unsupported extensions show a clear message.
- No change to BetterPlayer, audio, subtitles, or existing stream selection.
- Version `1.4.9-beta34.86+100`. APK build/device tests not yet run.

## v1.4.9-beta34.85 — Extension episode identity and selection safety
- Episode 0 can be locally marked watched when 75% played, without updating AniList/MAL/SIMKL; info page displays the local checkmark. AniZone server names now normalize extra whitespace extracted from site buttons.
- Extension Episode 0 ordering: explicitly numbered Episode 0 is placed before ordinary episodes even if Animenosub returns it last. Recognize explicit `Ep. 0` names or `episode-0` URLs if an extension reports a conflicting list index; other specials keep their ordering and streams keep their original URLs. Added regression tests.
- Tracker safety: progress now uses the actual regular episode number, not list index + 1. Episode 0/specials do not advance AniList, MAL or SIMKL; replaying an earlier episode does not downgrade progress. Continue buttons, resume timestamps and watched indicators use canonical episode IDs, with special resume keys separated. Added unit tests for episode-zero progress behavior.
- AniZone: distinguish regular /1–/12 episodes from /s1 specials. Guardian Fitz (Mushoku Tensei II 2023) is shown as Episode 0 before Episode 1 based on its verified source identity; other specials keep their source-defined position and do not shift regular episode numbers. Unit tests added.
- Explicit episode number 0 displays as `Episode 0` instead of being classified as unknown; missing numbers retain their source title. Fixed the parser source formatting.
- Preserve the actual episode number supplied by each approved extension; never silently replace a missing/invalid number with the position in the list.
- Keep decimal episodes and unnumbered specials labeled distinctly instead of rounding them to a potentially wrong canonical episode number. Sorting keeps their source-defined positions and uses stable numeric ordering within consecutive regular episodes.
- Episode grid and compact views show source episode identities; watch, context-menu and download actions resolve the original global list index even after pagination or filtering.
- Add Flutter unit coverage for One Piece episode 1000, decimal 1000.5, and unnumbered specials.
- Keep beta34.84 player audio switching, Android TV controls, 123Anime and existing extension search unchanged. The actual content of One Piece episode 1000 still needs user verification.
- Version `1.4.9-beta34.85+97`. APK build/device tests not run.

## v1.4.9-beta34.84 — Unified audio tracks and Android TV Back behavior
- Removed the duplicate **External HLS audio** choice that restarted the video. Both HLS and MKV now use the actual tracks reported by the active Media3/ExoPlayer player, selected directly without reopening playback.
- Show readable audio languages (Japanese, English, etc.) in a single list; hide synthetic HLS suffixes such as `Native_1` and `English_2`. Keep the underlying track identifiers intact for playback.
- Android TV: pressing Back when the playback controls overlay is visible hides it instead of immediately leaving playback. Press Back again with the controls hidden to leave the player. On phones, touching the video toggles the controls; system Back no longer stops at the player overlay.
- The existing beta34.83 English-first extension subtitle preference remains unchanged.
- Version `1.4.9-beta34.84+94`. Not yet compiled or device-verified.
