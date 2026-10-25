# AnimeStream — Changelog

Complete development history. Published GitHub Releases use the concise [RELEASE_NOTES.md](RELEASE_NOTES.md) for the latest three beta versions. Older entries remain here for reference.

## v1.4.9-beta34.90.4 — Scrollable provider picker and TV focus
- Completed AniList anime cards now keep the existing dimmed poster but render score badges on a dark theme-derived background, with accent-colored star and score digits without white outlines for a cleaner look. Applies to standard and extended cards; other statuses remain unchanged. No extra AniList API calls.
- Keep the existing Select Provider bottom-sheet design, colors and source ordering.
- Constrain the provider list to the screen and enable touch scrolling for all providers.
- On Android TV, DPAD up/down moves focus between source rows, Scrollable.ensureVisible follows focus, and a contrast focus border shows which source has keyboard focus independently of the selected green source.
- Version `1.4.9-beta34.90.4+120`; APK build/device verification pending.

## v1.4.9-beta34.90.3 — MAL Recommended score fix
- Display missing MAL recommendation scores by lazily fetching `mean` alongside age ratings, with shared cached requests.
- Preserve Tenrai MAL Characters and Related changes from beta34.90.2.
- Version `1.4.9-beta34.90.3+119`; APK build not yet verified.

## v1.4.9-beta34.90.2 — Tenrai MAL extras API
- MAL Recommended cards now fetch missing mean scores together with age ratings via one cached MAL API request per visible card; unknown scores remain `??`. Unit tests cover score conversion. No version bump for this incremental fix.
- Replace the discontinued Jikan public endpoint with Tenrai v1 for MAL Characters and Related requests.
- Retain the separate non-blocking loaders, diagnostic messages and lazy related cover fetching from beta34.90.1.
- Version `1.4.9-beta34.90.2+118`; API response validation and APK/device verification pending.

## v1.4.9-beta34.90.1 — Progressive MAL extras diagnostics
- Load MAL Characters and Related separately, so each section updates immediately on its own successful response.
- Remove the wait for up to eight MAL cover requests before publishing Related entries; each card retrieves its cover lazily and can display a text placeholder.
- Report character and relation request errors independently instead of silently treating network/rate-limit failures as empty results. Log counts and sanitized per-endpoint failures.
- Keep the series header responsive, preserve MAL manga/novel non-playable behavior and carry over beta34.90's compilation fix.
- Version `1.4.9-beta34.90.1+117`. APK and device verification pending.

## v1.4.9-beta34.90 — Fix MAL extras build
- Import `metadataTypes.dart` in `infoProvider.dart` so `AnimeMetadataSummary` resolves during release compilation.
- Retain beta34.89's non-blocking Characters/Related loading and update version to `1.4.9-beta34.90+116`.
- APK build and device testing not yet verified.

## v1.4.9-beta34.89 — Non-blocking MAL characters and related entries
- Fixed the beta34.88 series-page delay: Jikan characters no longer block initial metadata. Optional characters and relations load after the page appears, and each endpoint may fail independently without suppressing the other.
- Removed unsupported MAL anime details `related_manga` field and separated lightweight search/ranking fields from the detail request, preventing the MAL details request from discarding all metadata due to a field error.
- Fetch related adaptations, including manga and light novels, from Jikan's relations endpoint with a bounded cover lookup and an independent loading indicator. Non-anime entries remain non-playable.
- Character information and relations update the visible page when ready; existing Watch, playback, recommendation, source and rating behavior is unchanged.
- Version `1.4.9-beta34.89+115`. APK compilation and device verification pending.

## v1.4.9-beta34.88 — MAL Related and Characters
- When MAL supplies series metadata, Related now includes both anime and manga/light-novel adaptations from MAL API v2; relation labels are preserved.
- MAL character cards load independently from Jikan's MAL character endpoint with an eight-second timeout and twelve-hour cache. Failure leaves only Characters empty without losing series details.
- Manga and light-novel adaptation cards are marked non-playable, retaining the existing guard against opening those entries as anime.
- Added regression tests for manga/adaptation and anime/sequel relation parsing.
- Version `1.4.9-beta34.88+114`. Flutter build and APK/device verification pending.

## v1.4.9-beta34.87 — Centered Watch button and relocated R+ badge
- Moved the R+/18+ age-rating badge to the left of Watch/Info on the mobile series details page, retaining the existing rating classification and visibility rules.
- Reserved equal-width slots on both sides of Watch so the button stays horizontally centered regardless of whether the rating badge, tracker action or delete action is visible.
- Existing tracker buttons, watch/info action, subtitle behavior and provider logic are unchanged.
- Version `1.4.9-beta34.87+113`. APK build/device verification pending.

## v1.4.9-beta34.86 — Extension source settings
- Continue Watching now displays the same small outlined rating badges as other cards. Lazy, cached metadata lookups identify AniList adult entries and MAL R/R+/Rx entries without delaying cards or changing playback.
- Fix the small 18+/R+ badge plus: square black stroke caps surround all four ends, and the plus is inset to avoid clipping against the image boundary.
- Keep the upper endpoint of the R+/18+ circle fixed while moving only the lower endpoint away from the plus. Small search/recommended badges now have black outlines around the ring, plus and central R/18 for contrast.
- Fixed the upper-right opening of R+/18+ badges and added lazy, cached MAL rating lookups for anime recommendation cards.
- AniList adult-rated titles now explicitly use the same open-ring 18+ badge design as MAL Rx.
- Fixed Flutter compilation of runtime MAL age rating widgets by removing invalid const wrappers; version bumped for a new APK.
- MAL age badges now preserve the actual `rating` class: R = R in a complete circle, R+ = centered R with an open ring and plus at upper-right, Rx = original open-ring 18+ symbol. AniList retains its generic 18+ icon when `isAdult=true`. Applies to search, information, related, and recommended UI.
- MAL adult badge now requests age rating from the API and counts R+ and Rx as 18+ (not plain R); added unit tests.
- Increased the gap in the 18+ icon's circular outline only; plus sign, placement and sizing unchanged.
- Add open-ring 18+ symbol matching the selected artwork, at full 55px height next to the Watch/Info button and a smaller overlay on search, Related, and Recommended cards. Propagate AniList adult classification through search, information, and related metadata; use provider NSFW flags where available. The icon appears only when global 18+ is enabled and the specific title is classified adult.
- Metadata search uses exactly one provider: AniList when enabled, otherwise the first enabled MAL/Kitsu backup. Empty results and failures never cascade to another source. The 18+ switch now controls MAL `nsfw` requests and Kitsu local NSFW filtering.
- AniList search and extension AniList matching now respect the 18+ metadata setting: adult content remains excluded by default; enabling it removes the `isAdult: false` GraphQL filter. Search input is safely JSON-escaped.
- Added an off-by-default global 18+ content switch at the bottom of Metadata in Built-in providers. It hides APKs officially marked NSFW in the source picker and guards stream access. On change, it synchronizes unambiguously named on/off adult settings from approved extension sources only. Incompatible sources are skipped; no invented extension settings or changes to AniList/MAL/SIMKL tracking.
- Source settings gear added directly to Manage Providers > Installed and the nested Installed extension catalog, including apps installed outside catalogs. Available now defaults to Installed when APK extensions exist and Browse otherwise; manual tab choice is respected.
- Added **Source settings** for installed Aniyomi/Anikku extensions, including extensions installed outside repository catalogs.
- List the selected extension source's actual configurable preferences: lists, checkboxes, multi-select and non-sensitive text fields such as custom domains. Settings persist in per-source Android preferences; no fabricated domains.
- Changing a setting invalidates cached extension source objects so later search/episode/video calls see updated preferences. Existing stream picker/player code unchanged.
- Version `1.4.9-beta34.86+112`. APK build/device verification pending.

## v1.4.9-beta34.85 — Extension episode identity and selection safety
- Episode 0 can be locally marked watched when 75% played, without updating AniList/MAL/SIMKL; info page displays the local checkmark. AniZone server names now normalize extra whitespace extracted from site buttons.
- Extension Episode 0 ordering: explicitly numbered Episode 0 is placed before ordinary episodes even if Animenosub returns it last. Recognize explicit `Ep. 0` names or `episode-0` URLs if an extension reports a conflicting list index; other specials keep their ordering and streams keep their original URLs. Added regression tests.
- Tracker safety: progress now uses the actual regular episode number, not list index + 1. Episode 0/specials do not advance AniList, MAL or SIMKL; replaying an earlier episode does not downgrade progress. Continue buttons, resume timestamps and watched indicators use canonical episode IDs, with special resume keys separated. Added unit tests for episode-zero progress behavior.
- AniZone: distinguish regular /1–/12 episodes from /s1 specials. Guardian Fitz (Mushoku Tensei II 2023) is shown as Episode 0 before Episode 1 based on its verified source identity; other specials keep their source-defined position and do not shift regular episode numbers. Unit tests added.
- Explicit episode number 0 is labeled `Episode 0`; null, -1 and unknown numbers keep the extension's own special/unnumbered title. Rebuilt the parser source to fix a malformed line and accidental duplicate code.
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

## v1.4.9-beta34.80 — Complete extension episodes and safer search matching
- Separate Android extension episode diagnostics from player episode loading: **Manage Providers** diagnostics retain the first 100 entries and the total-count/truncation indicator; the regular series-page playback bridge now transfers the full episode list returned by the approved extension, so long-running series are no longer silently cut off at episode 100.
- Fix Dart extension search to read the actual Android `resultRelevance` field (rather than the nonexistent `relevance` field). An unverified, unrelated browse/catalogue response is no longer accepted as a normal title-search match; manual selection and the existing AnimeOnsen 403 search workaround remain available.
- Keep existing extension APK approvals, source settings, stream hoster resolution, subtitle/audio playback, SIMKL integration and metadata fallbacks unchanged.
- Version `1.4.9-beta34.80+90`. Flutter/Android compilation and device behavior have not been verified.

## v1.4.9-beta34.79 — Built-in provider and metadata controls
- Add **General → Built-in providers** between **Manage Providers** and **Cache Manager**, based on sofikuw/anImestream's provider settings page but adapted to the anime-only fork.
- Toggle built-in **AnimeOnsen, AniZone, Anikoto and Animegg** on or off without uninstalling extensions. Persist the disabled list in existing Hive Settings and restore it on startup. AniDB remains removed.
- Add **AniList, MyAnimeList and SIMKL** metadata controls and separately enable/disable the **MyAnimeList → Kitsu** fallback order. Disabling AniList routes supported discovery searches to enabled fallbacks; existing positive AniList IDs are not remapped to fallback IDs.
- SIMKL metadata control suppresses the series-page SIMKL cross-ID enrichment lookup, but does not log out the user or alter the SIMKL image cache. The previously identified AniList-login dependency for SIMKL episode artwork is intentionally left unchanged.
- Preserve APK repository management, approved extensions, existing playback and cache functionality. If a disabled built-in was the default source, switch the default to the first remaining available source when possible.
- Version `1.4.9-beta34.79+89`. Flutter compilation and device testing have not been verified.

## v1.4.9-beta34.78 — Extension repositories in Manage Providers > Available
- Move the existing Aniyomi extension repository interface into the **Available** tab of **Manage Providers [Beta]**. The tab now displays repository URL entry, trusted repository management, extension search, Installed / Updates / Browse filters, language filtering, and APK installation, updates and uninstallation instead of the older available Dart provider list.
- Embed the repository screen without a second app bar or navigation page; add an in-tab refresh control for repository catalogs and Android-installed extensions.
- Remove the separate **Extension Repositories** entry from Settings. The **Installed** tab retains its existing installed APK/source approval and diagnostic controls, as well as saved Dart providers.
- Reuse the existing local repository URLs, trusted certificate fingerprints and APK signature-verification process. No default external repositories are added and no repository storage migration is required.
- Version `1.4.9-beta34.78+88`. APK compilation and Android/mobile/TV UI testing have not yet been verified.

## v1.4.9-beta34.77 — MAL OAuth login PKCE fix
- Fix MyAnimeList authorization to use `plain` PKCE with the same code challenge and code verifier, rather than sending an SHA-256 challenge that MAL does not support.
- URL-encode OAuth authorization parameters; validate the token response's HTTP status and JSON shape before parsing credentials. Show a useful HTTP-status error instead of a raw FormatException when MAL returns HTML.
- Apply safe response parsing to refresh-token requests. No changes to the MAL/Kitsu fallback, extensions, HLS audio, ASS delay, or existing cache.
- Version `1.4.9-beta34.77+87`. Login still depends on the OAuth redirect registered for the MAL client ID; build/device verification pending.

## v1.4.9-beta34.76 — AniList metadata outage fallback (anime)
- Use read-only MAL v2 as first fallback and Kitsu as second for anime search, trending, currently airing and recently updated when AniList API fails.
- Adapt sofikuw/anImestream's anime metadata router and providers without depending on manga classes absent from this fork.
- Encode MAL/Kitsu IDs as separate negative application IDs; fallback result details resolve via their actual provider rather than issuing AniList GraphQL requests.
- Suppress AniList/SIMKL cross-database ID lookup for fallback-only entries to avoid accidental metadata/list ID corruption. Original source player and subtitle functionality remains intact.
- Existing positive AniList IDs do not yet dynamically remap to MAL on detail-fetch failure; no manga or configurable metadata toggles in this first port.
- Version `1.4.9-beta34.76+86`. APK compilation/device testing is not yet verified.

## v1.4.9-beta34.75 — Hourly cooldown for missing SIMKL episode images
- Retry missing SIMKL artwork no more than once an hour **per episode**, independently from all other episodes. Failed SIMKL requests use the same one-hour retry. Found artwork remains long-lived and is not refreshed on a timer.
- The selected streaming source defines the eligible episode list. SIMKL cannot trigger prefetch of future episodes (e.g. episode 16 while the selected provider only lists episodes 1–15).
- Newly added source episodes can be queried immediately without waiting for older episodes' cooldowns. One series-wide SIMKL request can resolve several eligible episodes at once.
- Keep the existing shared CacheManager/Hive image and metadata storage, cache controls, size limits and clear actions. Safely migrate positive art from beta34.74 while discarding the older series-wide cooldown.
- Version `1.4.9-beta34.75+85`. APK build and live SIMKL endpoint remain unverified. README unchanged.

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

## v1.4.9-beta34.66 — Re:ANIME missing JVM method diagnostics
- Re:ANIME in beta34.65 fails with `NoSuchMethodError` inside `getHosterList` while playing in Anikku on the same phone. The root method is not yet identified, so do not change working playback host classes speculatively.
- Report the **innermost** stream stage (e.g. `hoster_list`) instead of the generic `resolve_videos` wrapper.
- Extract only a validated Java method name, owning public class and JVM type descriptor from Android `NoSuchMethodError` into Stream test results. Never display arbitrary exception messages, full URLs, tokens, cookies or headers.
- Keep beta34.65 hoster routing diagnostics, beta34.64 mobile ASS toggle, and beta34.63 confirmed HLS audio.
- Version `1.4.9-beta34.66+76`; APK build and device check pending.

## v1.4.9-beta34.65 — Re:ANIME Hoster and DNS diagnostics
- For installed modern extensions declaring getHosterList, do not silently fall back to legacy episode getVideoList when the modern call fails; show the real hoster-list failure stage.
- Report the hostname of DNS lookup failures observed by the shared OkHttp client during an explicitly requested stream test. Do not expose full URLs, paths, headers, tokens or cookies.
- Distinguish hoster-list failures, hoster-video-list failures and legacy episode-video-list failures in Stream test results.
- Preserve beta34.64 mobile Ext sub, inbuilt subtitle providers and working beta34.63 separate HLS audio. README unchanged.
- Version `1.4.9-beta34.65+75`. Not yet APK built or tested on device; further Re:ANIME API and host compatibility work may be needed.

## v1.4.9-beta34.64 — Mobile Ext sub toggle + built-in ASS sources
- Fix missing **Ext sub** toggle on mobile by adding it to `infoMobile.dart`'s actual Episodes header (beside Sub/Dub and view toggle), with a compact control preserving the episode title.
- Include installed, user-approved extension sources and all four built-in provider options (AnimeOnsen, AniZone, Anikoto, Animegg) in global Primary/Secondary ASS selectors, even when a built-in is not in the currently active source list.
- Permit built-in providers in cross-source subtitle lookups and handle their legacy `VideoStream.subtitle/subtitleFormat` fields alongside extension `subtitleTracks`. Require a verified ASS format and matching preferred language; built-ins without ASS remain selectable but may yield no eligible subtitles.
- Preserve opt-in automatic lookup per anime, last successfully used Primary/Secondary, strict series/episode matching, and fallback to video-source subtitles.
- Preserve confirmed beta34.63 HLS audio playback integration unchanged. README untouched.
- Version `1.4.9-beta34.64+74`. APK build and device tests pending.

## v1.4.9-beta34.63 — HLS audio + cross-source ASS subtitles (experimental)
- Add an Android-local, loopback-only HLS master manifest bridge: for an extension returning a video-only HLS variant with external audio renditions, connect the video URL and reported audio tracks so native ExoPlayer can select audio. Original media/segment URLs are not proxied; bind only to 127.0.0.1 and restrict cleartext networking to the loopback domain. On bridge preparation failure, use the original video URL.
- Skip quality/track overrides that target the original variant after the alternate local HLS manifest is loaded. Apply the bridge to initial playback, server switching and preloaded next episode.
- Add global Primary/Secondary ASS source selectors and preferred language to Player Settings. Only enabled installed extensions are offered; configuration is saved locally.
- Add an **Ext sub** switch in the Episodes header, independent of Sub/Dub, off by default and saved per anime. When on, attempt external ASS loading asynchronously after playback begins. A manual Primary/Secondary selection in the player's subtitle menu becomes the preferred source next time for that anime.
- Match the exact normalized anime name uniquely, or reuse a previously manually confirmed source alias; require an unambiguous episode number. Never execute unapproved sources, guess unrelated matches, or switch video sources. Failure uses the original video source subtitles and is visible as a diagnostic in subtitle selection.
- Carry source-specific subtitle request headers into ASS rendering and content format inspection. The new subtitles are obtained automatically only with Ext sub enabled, while playback startup does not wait on network searches.
- Keep beta34.62 episode artwork, Discover 50/80/50, rolled-back pagination and 20-second pause dim. README is untouched.
- **Build correction:** The initial beta34.63 release build failed in `playerProvider.dart` because `dispose()` was accidentally declared on `PlayerProviderState`, which is not a `ChangeNotifier` and has no `_audioBridge`. Moved disposal into `PlayerProvider` without changing playback or subtitle behavior. Rebuild still pending.
- **Android release lint correction:** Explicitly declare `includeSubdomains="false"` for `127.0.0.1` and `localhost` in `animestream_loopback_security.xml` to resolve two fatal NetworkSecurityConfig lint errors; no lint checks disabled. Rebuild required.
- Version `1.4.9-beta34.63+73`. **No successful Flutter build or device validation yet**; HLS compatibility and cross-source subtitle matching need real-device testing (especially KickAssAnime and AniWaves).
 
## v1.4.9-beta34.62 — Extension episode thumbnails
- Use an extension's `SEpisode.preview_url` image for both graphical episode tile layouts, including the grid layout that previously always displayed the series cover.
- Resolve absolute, protocol-relative and relative episode image references in the native Anikku bridge against the installed source's HTTP base domain (or an absolute selected series URL). Only HTTP(S) URLs are passed to Flutter.
- When the episode thumbnail is missing or fails to load, fall back to the extension's series cover, then AniList cover, then a neutral placeholder; preserve card size and image crop.
- Do not change compact number-only tiles, source title matching, episode retrieval, player, subtitles, Discover counts or the reverted Manual Search Pagination.
- Version `1.4.9-beta34.62+72`. **Not build- or device-tested.** Verify an extension that returns `preview_url`, another that omits it, and a broken image URL. Confirm playback still works.

## v1.4.9-beta34.61 — Double Discover lists
- Discover / **Recently Updated** requests 50 airing schedule entries instead of 25, with the existing country/adult filters and ID deduplication preserved. Actual displayed titles may be fewer than 50 when entries repeat or are filtered.
- Discover / **Recommended** requests 50 AniList recommendations instead of 25; skip empty media recommendations gracefully.
- Discover / **This Season** loads up to 80 titles by requesting two pages of 40. Keep Home / Aired This Season at its original 40 results and avoid mixing its cards into Discover's independent seasonal list.
- Clear the two other Discover lists on refresh before rebuilding cards, avoiding duplicate accumulated entries.
- Keep trending, player behavior, extension search and the 20-second OLED pause protection unchanged. The Manual Search Pagination experiment from beta34.60 was rolled back to beta34.59 behavior.
- Version `1.4.9-beta34.61+71`. **Not yet APK-built or device-tested.** Verify all three horizontal Discover lists, refresh behavior and that Home is unchanged.

## v1.4.9-beta34.60 — Manual Search pagination (rolled back in beta34.61)
- Historical beta34.60 experiment added paged Anikku Manual Search and a Load more button.
- **Rolled back in beta34.61** at the user's request; the seven affected search/bridge/UI source files were restored to the user-verified beta34.59 implementation.
- beta34.61 keeps the expanded Discover lists, but **does not include Manual Search Pagination**.

## v1.4.9-beta34.59 — Extension series-page source relinking
- User-confirmed regression in the beta34.58 family: **Manage Providers** can find source episodes/streams (e.g. AnimeOnsen [Ext], HTTP 200, one DASH video and nine subtitle tracks) while the series page reports no matching results for installed extensions.
- Cause under investigation: Manage Providers probes historically omit `sourceId` and use the first source; series-page searches, episodes and streams specify a persisted approved source ID. Beta34.57 added safe name/language fallback only to Source Settings, not to the series playback path.
- Pass the existing approved source's exact name and language through the series search/episode/stream Dart bridge and Kotlin probes. If a saved source ID cannot be found after restart, use the shared runtime's **unique exact name+language** fallback. Never use first-source fallback when an explicit ID is supplied and never silently select an ambiguous source.
- Preserve source approvals, AniList identity verification, manual search behavior, Host API playback/headers/subtitles, and the 20-second OLED pause dimming of beta34.58. Manage Providers probes with no selected source ID remain unchanged.
- Version `1.4.9-beta34.59+69`. **User-confirmed on device:** the previously failing extension results in series pages now work after the beta34.59 source-identity fix. The report confirms recovery of the series-page flow; it does not separately document stream playback, 20-second pause-dimming or every individual source after restart.

## v1.4.9-beta34.58 — OLED pause-dimming delay to 20 seconds
- Increase the `Watch` screen OLED Pause Protection timer from 8 to **20 seconds** after playback is paused (`lib/ui/pages/watch.dart`).
- Keep the existing dark overlay opacity and fade animation, immediate restoration on resume, and timer cancellation while playing or buffering.
- This is **not** a network, buffer, stream resolution or video initialization timeout change; playback controllers and extensions are untouched.
- Version `1.4.9-beta34.58+68`. **Build and device testing pending.** Verify the image dims after ~20 seconds of continuous pause and clears immediately on resume.

## v1.4.9-beta34.57 — Restore Source settings after app restart
- User report: after restarting AnimeStream, **all** approved extension Source settings fail with `settings_load_source` / `IllegalStateException` (`invalid_source_state`). Disabling and re-enabling the sources restores access.
- During Source settings only, if a previously approved source ID is no longer found among the loaded APK's sources, resolve the user-approved source using an exact and unique source name + language match. No fallback to an arbitrary or first source; if validation fails, keep the existing safe error rather than selecting another source.
- Pass approved name/language from AnimeStream's locally restored approval metadata through Flutter and Android bridges. Existing signing key and APK version checks for approvals are retained; no automatic execution of unapproved sources.
- Make the existing auto-save behavior explicit: each successfully saved setting displays a confirmation inside the menu, and a Done button closes the sheet. Multi-select Save/Cancel remains.
- Version `1.4.9-beta34.57+67`. **Not yet built or device-tested.** Restart the app, reopen Source settings across AniWaves and other installed extensions without re-enabling sources, verify choices persist, and regression-test video playback.
## v1.4.9-beta34.56 — Source Settings R8 / AndroidX Preference compatibility
- The user's beta34.55 AniWaves.ru [Ext] device test shows `settings_build_screen`, `NoSuchMethodError`, missing method `getContext`, from `AniWaves.setupPreferenceScreen`; title matching, hoster choices and video playback remain confirmed working.
- Root-cause hypothesis: installed extension bytecode calls `PreferenceScreen.context` (`Preference.getContext()` on the JVM), but host release R8 shrinking may remove or rename AndroidX Preference members because those cross-APK references are invisible to the host app's static analysis.
- Add keep rules for `androidx.preference.**` types, interfaces and methods in `android/app/proguard-rules.pro`, preserving extension-facing AndroidX Preference linkage during minified release builds.
- This is a host-level compatibility fix: no source-specific filtering logic, user preferences, player/subtitles, repository URLs or existing extension APKs are changed.
- Version `1.4.9-beta34.56+66`. **User-confirmed on Android device:** AniWaves.ru [Ext] Source settings now opens and displays all ten extension-defined settings, so the prior `getContext` linker failure is resolved on the tested build. The UI saves each change immediately and has no global Save/confirmation button. Subsequent re-opening sometimes fails with `settings_load_source`, `IllegalStateException` (`invalid_source_state`); the user reports disabling and re-enabling extensions works around it. Screenshot of this error shows AnimeOnsen expanded, so the specific affected source must be confirmed before attributing the failure. Persistence after app restart and other sources have not yet been verified. No player/subtitle changes.
## v1.4.9-beta34.55 — Repair Aniyomi hoster Dart build
- Repair the truncated `RegExp` in `aniyomiExtensionProvider.dart` and restore the complete hoster-name fallback / `VideoStream` creation block.
- Remove the mistakenly duplicated trailing code after the provider class. The malformed file previously caused cascading Dart compiler errors involving `StateError`, `VideoStream`, `sources.dart` and `infoProvider.dart`.
- Preserve explicit Hoster labels and infer a hoster only from structured legacy quality strings such as `SUB - Omega - VidMoly - 720p`. Ignore synthetic labels such as `no_hoster_list`.
- Keep stream quality, media URLs, subtitle/audio metadata and HTTP request headers unchanged.
- Version `1.4.9-beta34.55+65`. **User-confirmed on an Android device:** AniWaves.ru [Ext] matches the title, presents distinct stream choices (DatSaV 360p/480p and Vidplay 720p) and successfully plays the selected stream. The previously broken compile path is therefore functional in the installed test APK, although GitHub Actions build status was not independently reviewed and other hosts/settings remain unverified. No subtitle renderer or extension repository storage changes.

## v1.4.9-beta34.54 — Unsuccessful hoster build correction attempts
- Two beta34.54 development branches attempted to correct the beta34.53 hoster labeling code, but retained an unterminated Dart regex and duplicated trailing code; these branches are **not suitable for APK builds**.
- No separate verified beta34.54 release or successful device test is claimed. Superseded by the beta34.55 source repair.

## v1.4.9-beta34.53 — Server labels and source settings diagnostics
- Ignore synthetic `no_hoster_list` hoster labels. For structured legacy quality labels such as `SUB - Omega - VidMoly - 720p`, show the explicit server component as a fallback.
- Preserve actual hoster names from modern Anikku extensions; retain all playback URLs, subtitle tracks, audio metadata and request headers.
- Show safe missing-method hints and host call stages for failed Source settings setup, instead of a generic `NoSuchMethodError` alone. Exact failing AndroidX API method still requires device diagnosis.
- Version `1.4.9-beta34.53+64`. Not yet built/device-verified. Existing subtitle glyph issue remains deferred.

## v1.4.9-beta34.52 — Preserve extension video hoster labels
- Keep each Anikku Hoster's display name associated with the videos it returns, including videos resolved later by `resolveVideo` or `getVideoUrl`.
- Show the hoster in AnimeStream's server selection (e.g., `AnimePahe [Ext] • Kwik`) while retaining the source identity and original quality, URLs, headers, subtitles and audio metadata.
- Direct/legacy episode-only extensions keep the existing server label. Suppress control characters and cap hoster display names at 80 characters.
- Improve source-setting list labels so users see human-readable entries instead of internal option keys when available.
- Version `1.4.9-beta34.52+63`. No source-specific special cases, playback decoder changes or subtitle renderer modifications. **Build and device tests pending.**

## v1.4.9-beta34.51 — Extension episode recovery and safe diagnostics
- Attempt each saved [Ext] source episode link at most once per page load. If it fails or returns no episodes, continue ordinary search instead of repeating the same stale link for every title variant.
- Track bounded extension search, title-match and episode-fetch failure stages without exposing source URLs, request headers or tokens.
- Show a clear manual-search failure type instead of silently reporting “No Results” on network/runtime errors.
- Report safe source-preference error category, stage and missing Host API class identifiers when available.
- No player, subtitle renderer or AnimeOnsen search fallback changes. Version `1.4.9-beta34.51+62`.
- **User-confirmed on device:** previously failing installed [Ext] sources now work again in beta34.51. The report follows the missing-episode problem; not every source, stream host or settings option has been individually verified.

## v1.4.9-beta34.50 — Yūzōnō multi-select preferences
- Add generic `MultiSelectListPreference` support to the installed-extension Host API bridge and settings UI, including checkbox lists and Save/Cancel.
- Reject unknown values and oversized selections; persist validated string sets using the extension's existing per-source preference screen.
- Targets AniWaves.ru's source-declared **Exclude Servers** and **Exclude Types**, while remaining usable by other compatible Anikku extensions.
- AnimeOnsen fallback search, player, subtitles and working Animenosub integration remain unchanged.
- Version `1.4.9-beta34.50+61`. **Build/device tests pending.**

## v1.4.9-beta34.49 — Manual extension match and artwork integration
- Both manual source dialogs now save a confirmed [Ext] match after loading episodes, so reopening the same AniList series can reuse that source alias.
- Keep source-specific artwork for selected matches and prefer per-episode previews where available in episode cards, otherwise falling back to the source cover and AniList cover.
- Maintain existing AniList identity checks for automatic matches. No changes to player, subtitle rendering, AnimeOnsen fallback, or extension installer.
- Version `1.4.9-beta34.49+60`. Build and device tests pending.

## v1.4.9-beta34.48 — Enable all installed extension sources
- Add **Enable all installed sources** in Manage Providers [Beta] → Installed, with an explicit confirmation listing all APKs to be activated.
- Skip extensions whose approved sources are already enabled. Run discovery sequentially for the remaining packages; continue after individual failures and display enabled/skipped/failed counts with a failure list.
- Preserve the existing per-package APK signing fingerprint, versionCode recheck, locally persisted approvals, and manual activation safety model. No extension is executed automatically at startup.
- Correct misleading provider-management helper text: approved installed Android [Ext] sources can run; separately downloaded Dart provider code remains stored only.
- Version `1.4.9-beta34.48+59`. **Build and device verification pending.** Beta34.47 playback was confirmed by user.

## v1.4.9-beta34.47 — Legacy lazy video URL compatibility
- Resolve non-playable placeholder video URLs through modern `resolveVideo(Video)`, followed by legacy `getVideoUrl(Video)` only when a valid video-page URL exists **and** the extension supplies a resolver. Avoid a new HTTP request from the generic default parser.
- Retain subtitle/audio track lists, custom headers and video titles by copying the original Video with the final playable URL.
- Skip extra requests for video entries already containing valid HTTP/HTTPS URLs.
- Preserve confirmed beta34.46 playback, beta34.45 AnimeOnsen search fallback and the deferred non-Latin subtitle glyph issue.
- Version `1.4.9-beta34.47+58`. Build and device tests pending.

## v1.4.9-beta34.46 — Generic Anikku Hoster APIs
- Add modern Anikku 1.6 hoster-list and hoster-specific video request/parse hooks to the shared `AnimeHttpSource`.
- Add legacy `getVideoUrl` / `fetchVideoUrl` API hooks for extensions that resolve a video URL separately.
- Skip hoster network calls for legacy episode-only sources unless they implement a hoster parser.
- Preserve beta34.45 AnimeOnsen HTTP 403 search fallback and do not change subtitles or the player.
- Version `1.4.9-beta34.46+57`. **Build and device regression tests pending.**

## v1.4.9-beta34.45 — AnimeOnsen extension 403 search fallback
- Detect HTTP 403 on the installed AnimeOnsen extension's Meilisearch endpoint, and only in that case search using the already-working built-in AnimeOnsen v4 API.
- Preserve title identity via the shared AnimeOnsen content ID, then continue episode retrieval, video resolution and subtitle handling in AnimeOnsen [Ext].
- Show fallback status in Manage Providers diagnostics, without exposing tokens.
- Built-in AnimeOnsen and other extensions unchanged. **User confirmed the beta34.45 fix works on device**, following the earlier HTTP 403 search failure. Full playback regression checks for this beta have not been separately confirmed.
- Keep deferred non-Latin subtitle glyph issue unchanged.

## v1.4.9-beta34.44 — Extension source settings (list/switch)
- Expose source-defined preferences through the shared native `ConfigurableAnimeSource.setupPreferenceScreen` API, not per-site hardcoding.
- Add **Source settings** on enabled `[Ext]` providers in Manage Providers. List values and toggles are validated and saved to source-specific SharedPreferences.
- Supports Animenosub's declared quality, SUB/RAW type and preferred server lists in principle; device validation is still needed.
- No code changes to external audio playback or the deferred non-Latin subtitle glyph issue.
- Version `1.4.9-beta34.44+55`. **Build and device tests pending**; beta34.43 is the latest user-confirmed playback reference.

## v1.4.9-beta34.43 — Preserve external audio and subtitle metadata
- Carry extension-provided external audio URLs, languages and labels from Android's playback-only bridge into Dart `VideoStream.externalAudioTracks`, alongside existing subtitle tracks.
- Show external audio and subtitle track counts in the server selection interface without exposing signed URLs.
- Do not present external standalone audio as selectable Better Player tracks; audio-file synchronization/mixing is not implemented.
- Version `1.4.9-beta34.43+54`. **User-confirmed on-device:** AnimeOnsen [Ext] plays video and reports 9 subtitle tracks in the interface. Selection/rendering of all nine individual tracks and Animenosub playback on this beta have not been separately verified.

- **Known subtitle issue (deferred):** During user playback testing, one subtitle language believed to be Arabic displays missing-character glyphs (squares with crosses). The exact language and cause are not confirmed. Other tested subtitles were not reported affected. No renderer/font changes in this beta; leave for later investigation.

## v1.4.9-beta34.42 — Hoster resilience and lazy video resolution
- Add Anikku-compatible `AnimeHttpSource.resolveVideo(Video)` default hook.
- Resolve video placeholders when necessary, preserving already-playable HTTP/HTTPS URLs.
- Isolate failing hosters so other hosters can still return streams; retain the underlying error if all fail.
- **User confirmed working playback** following this beta; used as regression reference.

## v1.4.9-beta34.41 — Parsed HTML source Host API
- Add the missing `ParsedAnimeHttpSource` shared superclass and Jsoup parsing hooks for search, episode lists, hosters and video listings.
- Extend `AnimeHttpSource` parsing/sorting hooks used by Yūzōnō multisrc extensions.
- **User confirmed Animenosub [Ext] search, 16 episodes, several SUB/DUB/RAW stream choices and actual Better Player playback.** AnimeOnsen [Ext] remained working.

## v1.4.9-beta34.40 — Source-discovery diagnostics
- Identify failure stage (entry point, construction, source factory or metadata), missing classes and redacted exception chain when enabling installed sources.
- Diagnosed Animenosub's missing `eu.kanade.tachiyomi.animesource.online.ParsedAnimeHttpSource`.
- Branched from the confirmed beta34.38 Host API; the beta34.39 embed experiment was **not** included.

## v1.4.9-beta34.38 — OkHttp extension ABI
- Add `OkHttpExtensionsKt` functions `await`, `awaitSuccess`, `asObservable`, `asObservableSuccess` and `HttpException`.
- Fix `NoClassDefFoundError` during AnimeOnsen stream retrieval.
- Correct the duplicate beta34.38 branch ref that initially built beta34.37 code instead.
- **User confirmed AnimeOnsen [Ext] video streams work with the correctly built beta34.38.**

## v1.4.9-beta34.37 — Redacted extension linkage diagnostics
- Report safe missing-class names, failure stage, exception chain and relevant host call sites during extension video resolution.
- Pinpointed `OkHttpExtensionsKt` as the missing playback dependency rather than guessing from an empty server list.

## v1.4.9-beta34.36 — Reliable Android uninstall feedback
- Await Android's uninstall result, then recheck whether the APK is installed.
- Offer a system **App info** fallback if removal was cancelled or the package remains.
- Replace the premature “Confirm uninstall in Android” toast with a result-driven message.

## v1.4.9-beta34.35 — Auto-load catalogs and improve stream diagnosis
- Fetch saved repository indexes automatically when the Extensions page opens, surfacing loading and fetch errors.
- Include installed and uninstalled entries under Browse.
- Switch to Android's dedicated uninstall-package action and improve redacted playback status diagnostics.
- 123Anime's embed/playlist extraction remained unresolved.

## v1.4.9-beta34.34 — Extension network sessions
- Implement Anikku-compatible `AndroidCookieJar` and shared OkHttp cookie/session handling with an Android TV fallback where WebView is absent.
- Add missing HTTP PATCH request helper API.
- Preserve installed APK certificate verification and source approvals.

## v1.4.9-beta34.33 — Shared runtime and source preferences
- Add source-scoped Android SharedPreferences methods used by configurable Anikku extensions.
- Cache source instances and invalidate cached objects on APK version/path changes.
- Full extension preference-screen UI and broad Host API parity remained incomplete.

## v1.4.9-beta34.32 — Extension library UI and uninstall
- Organize extensions into Installed, Updates and Browse, with searching, language filters, icons and deduplicated catalog entries.
- Add an Android uninstall entry for installed extension packages (separate from disabling a source).
- Existing signed installation and local repository URLs remain in place.

## v1.4.9-beta34.31 — APK installer lifecycle
- Refresh installed extension versions after returning from Android's installer.
- Add manual installed-package refresh, avoid Android 11+ package-visibility false negatives, and clean stale APK cache.
- **User later confirmed APK installation works**, though further uninstall feedback improvements were needed.

## v1.4.9-beta34.30 — Signed extension installation
- Install or update extensions from user-added local catalogs using HTTPS downloads and Android's own confirmation UI.
- Verify APK signing cryptographically and compare signing certificate SHA-256 with the user-approved repository fingerprint.
- Display installed versions and updates; persist approved per-APK source selections only while APK signer and version remain unchanged.
- Add factory-class metadata handling. Third-party code still requires explicit activation.

## v1.4.9-beta34.28 — Shared extension model ABI
- Align `AnimeFilter`, `Video`, `Hoster`, `SAnime` and `SEpisode` signatures with more Anikku extension bytecode.
- Add a local ABI diagnostic without executing extension APK code.

## v1.4.9-beta34.27 — Anime source interface alignment
- Separate `AnimeSource` from `AnimeCatalogueSource` APIs, with coroutine/Rx bridging and related-anime compatibility placeholders.

## v1.4.9-beta34.26 — Multi-source extension routing
- Enumerate multiple source IDs per installed APK and route search, episodes and streams to the selected source.
- Add explicit enablement of sources shown as `[Ext]`; approval was initially memory-only.

## v1.4.9-beta34.25 — Shared extension host foundation
- Consolidate class loading, Injekt setup, source factories and modern/legacy API calls into a common Android runtime.

## v1.4.9-beta34.24 — Locally pinned repository trust
- Add user approval of `repo.json` certificate fingerprints and detection of changed repository keys.
- HTTPS metadata fetch limits/redirect protection; APK signature enforcement followed in beta34.30.

## v1.4.9-beta34.23 — User-managed extension catalogs
- Store entered Aniyomi/Yūzōnō `index.min.json` URLs locally, browse catalog contents and show source metadata.
- Do **not** bundle the Yūzōnō catalog URL in the repository.

> **Branch history:** Beta34.29's alternate source/episode changes were intentionally excluded from this development line (beta34.30 branched from beta34.28). The beta34.39 embed diagnostics experiment was also not merged into the beta34.40→34.43 line. Beta34.22 was an earlier catalog installation experiment, not the parent of beta34.23.

---

## v1.4.9-beta34.21 — Inspect Aniyomi subtitle formats; search fallback
- Detect ASS/SSA, WebVTT and SRT using actual subtitle file headers and timestamp syntax. Bound HTTP reads, preserve stream headers, and do not log signed URLs.
- Gradually populate subtitle format labels without assuming unknown formats are ASS.
- Retry season-specific Aniyomi searches without season suffix and with punctuation-normalized titles. Validate series/season identity before auto-linking.
- No changes to AnimeOnsen DASH decoding. Build/device verification pending.

## v1.4.9-beta34.20 — Fix grey subtitle selection and Aniyomi season searches
- Eliminate Provider lookup in a separate subtitle modal route; use the player notifiers captured in the watch page, with an explicit bottom-sheet height, scrollable track list and theme text colors.
- Retry the base title when a season-specific extension search returns no results (including Manual Search); don't automatically select unrelated seasons.
- Keep existing AnimeOnsen DASH playback and all subtitle support unchanged.
- Device build/test pending.

## v1.4.9-beta34.19 — Select all Aniyomi subtitle tracks
- Playback bridge carries every subtitle track, rather than only the first, with source-provided language/label and detected format.
- VideoStream supports optional multiple tracks without breaking single-subtitle providers.
- Subtitle button offers a track list and Off; long press still opens subtitle settings.
- Existing Android libass overlay handles selected ASS/SSA tracks; normal subtitle renderer handles VTT/SRT. Language preference follows the current playback session when switching episodes or video streams.
- APK compilation and device testing remain pending.

## v1.4.9-beta34.18 — Aniyomi source and DASH playback fixes
- Attempt up to seven distinct AniList title aliases for external extension searches without auto-selecting ambiguous results.
- Treat .mpd and .dash as MPEG-DASH manifests before performing HTTP HEAD detection; do not parse DASH as HLS or prematurely apply HLS quality tracks.
- Show a recoverable error screen if player setup throws; preserve the existing player implementation.
- Build and device validation pending.

## v1.4.9-beta34.17 — Remove retired AniDB sources
- Removed AniDB V1/V2/V3 from the built-in provider list and internal source registry, including the legacy V3 alias.
- Deleted the retired AniDB HTML scraper and stream extraction implementation (lib/core/anime/providers/anidb.dart).
- Preserved AniList metadata handling, other native providers and installed Aniyomi extensions.
- Older historical entries retained for reference. Build and device tests pending.

## v1.4.9-beta34.16 — Aniyomi integration into AnimeStream
- Installed Aniyomi APK sources are registered in AnimeStream's normal source selector as [Ext].
- Flutter provider adapter reuses Aniyomi search, episode-list and on-demand stream resolution APIs; passes URL, headers, quality and one subtitle track to the existing player.
- Exact-title/unique AniList alias matches can load automatically; uncertain matches require manual selection, saved per anime and extension.
- Source episode preview thumbnails are exposed where available, native sources remain unchanged and external-source downloads stay disabled.
- Diagnostic secrets must remain redacted; player-only stream URLs are passed to Flutter without logging.
- Build and device validation still pending; advanced hoster and multi-track playback compatibility not assured.

## v1.4.9-beta34.15 — Cache-aware source response diagnostics
- Add application-interceptor tracing of stream-stage requests including responses from OkHttp cache.
- Parse only known 123Anime JSON responses to report server-tab count, episode target presence/shape, grabber presence and status; never expose URLs or auth tokens.
- Diagnose zero-stream extraction without modifying source playback behavior.
- Requires build and device verification.

## v1.4.9-beta34.12 — AniList and episode probe (archived from release notes)
- Ranked AniList matches and added manually selected episode list probing.

## v1.4.9-beta34.14 — Stream extraction diagnostics
- Report stream_list_empty when no videos resolve and classify network stage failures without showing signed URLs.
- Improve 123Anime stream-resolution diagnostics while retaining AnimeOnsen stream support.
- Build and device tests pending.

## v1.4.9-beta34.11 — Search routing (archived from release notes)
- Route 123Anime plain-text searches to /search.

## v1.4.9-beta34.13 — Aniyomi stream list diagnostic
- Implement Video, Track and Hoster model ABI compatibility and the legacy fetchVideoList Rx request/parser flow.
- Display a per-episode Test streams button, restricted to user-selected episodes. Return sanitized stream quality/format/host and audio/subtitle counts, not raw media URLs or auth headers.
- No streaming player integration yet. Build and device testing required.

## v1.4.9-beta34.10 — Search endpoint diagnostics (archived from release notes)
- Confirmed that 123Anime works through its /search route rather than /filter.

## v1.4.9-beta34.12 — AniList source matching and episodes
- Use existing AniList GraphQL client for English/romaji/native/synonym ranking of Aniyomi extension results, with confidence thresholds, AniList cover fallback, source labels, and separate seasons / Sub/Dub markers.
- Test manual selection of a source result through fetchEpisodeList and show episode names/numbers/paths with guarded errors and 25-second wait.
- No streams or player integration yet; build/device validation pending.

## v1.4.9-beta34.9 — Search diagnostics (archived from release notes)
- Source requests traced without leaking tokens, with relevance warnings.

## v1.4.9-beta34.11 — Source-specific search routing and alternate title labeling
- For plain text searches only, 123Anime's /filter?keyword= is routed to its working /search?keyword=; the extension's HTML parser stays unchanged.
- Exclude advanced-filter and unrelated extension requests from rewriting. Avoid unnecessary duplicate probes.
- AnimeOnsen titles in Japanese/romaji are labeled possible alternate matches pending AniList verification.
- Build and device tests pending.

## v1.4.9-beta34.8 — JSON/Okio runtime (archived from release notes)
- Added Kotlin Serialization Json-Okio runtime to support AnimeOnsen extension search.

## v1.4.9-beta34.10 — Alternate source search diagnostics
- Show search result relevance without assuming English titles must equal romanized Japanese titles.
- Compare /filter versus /search for installed 123Anime with a bounded extra diagnostic request; no automatic fallback or source change.
- AnimeOnsen's four Japanese-title results were returned with HTTP 200 and a Bearer token, and may be correct alternate-title matches.
- Build and device verification required.

## v1.4.9-beta34.7 — Okio ABI fix (archived from release notes)
- Keep Okio JVM method descriptors to support dynamically loaded extensions.

## v1.4.9-beta34.9 — Search relevance and safe network diagnostics
- Added per-request HTTP host/status, authorization presence, query match comparison and mitigation header diagnostics, without logging query values, tokens or cookies.
- Flag suspicious search results when displayed titles do not include the submitted phrase.
- Beta 34.8 device tests: 123Anime executes but returns generic titles for "Ascendance of a Bookworm"; AnimeOnsen reaches HTTP 403.

## v1.4.9-beta34.6 — URL and OkHttp compatibility (archived from release notes)
- Added setUrlWithoutDomain methods and upgraded OkHttp to 5.4.0.

## v1.4.9-beta34.8 — Serialization JSON Okio runtime
- Add kotlinx-serialization-json-okio 1.9.0, update serialization-json from 1.6.3 to 1.9.0 and preflight the class OkioStreamsKt. Requires build/device validation.

## v1.4.9-beta34.5 — Host API and Jsoup compatibility (archived from release notes)
- Added JsoupExtensionsKt parsing helpers, NetworkHelper and its registration, and the AnimeHttpSource getNetwork() bridge.

## v1.4.9-beta34.7 — Preserve Okio ABI
- Keep `okio.**` to retain `ResponseBody.source(): okio.BufferedSource` method descriptor for AnimeOnsen. The user confirmed 123Anime search succeeds in beta34.6 with 28 Naruto results. Fix not yet device-tested.

## v1.4.9-beta34.4 — Network and Json host integration (archived from release notes)
- Added RequestsKt HTTP helpers, Json Injekt registration and UI newline fix.

## v1.4.9-beta34.6 — URL ABI and OkHttp dependency
- Add SAnime/SEpisode setUrlWithoutDomain methods, align OkHttp to 5.4.0, log runtime ResponseBody source signatures. Build/device compatibility unverified.

## v1.4.9-beta34.3 — Better extension diagnostics (archived)
- Show underlying error chain and register Android Application in Injekt.

## v1.4.9-beta34.5 — Aniyomi Host API compatibility
- Add JsoupExtensionsKt, minimal NetworkHelper, protected getNetwork() ABI bridge, and Injekt registration. Not yet build- or device-verified.

## v1.4.9-beta34.2 — Extension search runtime dependencies (archived)
- Added Injekt core and kotlinx.serialization dependencies and keep rules.

## v1.4.9-beta34.4 — Aniyomi network and JSON host compatibility
- Port Aniyomi RequestsKt GET/POST/PUT/DELETE request builders and basic coroutine HTTP calls. Register Json in Injekt and fix literal newline labels. Build/device unverified.

## v1.4.9-beta34 — Aniyomi search probe (archived)
- Added manually triggered extension search and initial Flutter/Android search diagnostics; runtime compatibility incomplete.

## v1.4.9-beta34.3 — Better extension diagnostics
- Nested error chain and stack trace, collapsible class diagnostics; Android Application registered in Injekt before search; unverified.

## v1.4.9-beta34.2 — Extension search runtime dependencies
- Added Injekt runtime dependency, serialization keep rules and missing-runtime diagnostics for Aniyomi search.
- Build and runtime compatibility remain unverified.

## Archived release notes — beta33.3 and earlier

## v1.4.9-beta33.3 — Kotlin class visibility diagnostics
- Added Kotlin stdlib dependency and host/isolated classloader probes for Function0, Intrinsics, Unit and Continuation.
- User testing showed missing Kotlin runtime classes in release, motivating Beta 33.4.

## v1.4.9-beta33.2 — Manual instantiation test
- Added explicit instantiation diagnostics and UI confirmation; no automatic extension execution.
- User testing showed NoClassDefFoundError for Kotlin Function0.

## v1.4.9-beta33.1 — ABI diagnostics
- Fixed diagnostic ordering so constructor and AnimeSource compatibility information is shown.
- User testing confirmed class loading and parameterless constructors for 123Anime and AnimeOnsen.

## v1.4.9-beta32 — Isolated class loading diagnostics
- Introduced and refined isolated child-first class loading and DEX/superclass diagnostics.
- User testing showed successful class resolution, resolving earlier final-superclass verification conflicts.

# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta31 — Aniyomi Host API scaffolding (partial)
- Enabled explicit ProGuard/R8 keep rules for dynamically referenced Host API and networking classes in release APKs.
- Added hostApiMethodProbe for selected JVM method signatures without executing extension code. This is a diagnostic probe, not ABI certification.
- Added first-pass Kotlin source contracts for AnimeSource, AnimeCatalogueSource and ConfigurableAnimeSource, plus minimal placeholder model types. These are NOT verified binary compatible and cannot yet execute extensions.
- Expanded SAnime and SEpisode model interfaces with upstream fields, companion create() factories, concrete implementations, and update/fetch enums. Added kotlinx-serialization JSON dependency. Still not binary ABI tested.
- Added an initial AnimeHttpSource HTTP/RxJava bridge for legacy popular/search/latest/detail/episode request-and-parse hooks. This is partial and not binary-compatibility verified.
- Complete model field/method ABI, network host/injection, preference storage, newer API hooks, and real class instantiation remain unimplemented. Do not use this as a working extension runtime.
- Added a third non-initializing class-resolution test using Android's installed-package context classloader, in addition to DexClassLoader and PathClassLoader.
- Added Android runtime dependencies RxJava 1, OkHttp, Jsoup, AndroidX Preference and Kotlin coroutines; their integration is not build-verified.
- Added hostApiMissingClassNames and hostApiReadinessStatus so missing dependencies can be read directly.
- Added a wider requiredHostApiProbe, requiredHostApiMissingCount and hostApiRuntimeReady to inspect required source models, networking and dependency-injection classes.
- Added packageContextClassLoaderResult to extension diagnostics. This may reveal whether package/split class paths explain class-load failures; it does not supply missing Aniyomi Host API classes.
- Reviewed upstream Aniyomi AnimeSource, AnimeCatalogueSource, ConfigurableAnimeSource and AnimeHttpSource APIs. They require additional model, RxJava, coroutine, OkHttp and dependency-injection types. Binary-compatible host API implementation and extension instantiation are NOT yet complete.
- No APK build or device testing performed.

## v1.4.9-beta30 — ASS motion smoothing controls and Aniyomi compatibility (in progress)
- Add persisted player-bar dropdown: Motion Smoothing Av / Automatisk positionsinterpolering.
- IMPORTANT: motion interpolation rendering is not yet implemented; the control currently stores the requested mode only, and does not change the ASS texture motion.
- Next Aniyomi work: implement binary-compatible AnimeSource, AnimeCatalogueSource, AnimeHttpSource and ConfigurableAnimeSource plus required dependencies before class loading and instantiation can succeed. No runtime compatibility layer has been implemented yet.
- No APK build or device test performed.

## v1.4.9-beta29 — Aniyomi host API compatibility (in progress)
- Start implementing binary-compatible Aniyomi host API support for third-party extensions, beginning with ConfigurableAnimeSource and AnimeHttpSource identified in beta28.
- Add an ASS FPS popup in the in-player control bar: Auto plus 1–30 FPS, with live updates to the active overlay and persisted selection. The existing 24/30/60/120 FPS Player Settings selector remains available.
- Preserve beta28 ASS settings and diagnostics.
- Host API runtime integration, class instantiation, and playback are not implemented or verified yet. Do not treat this branch as a working extension release.

## v1.4.9-beta28 — ASS 24 FPS and Aniyomi diagnostics visibility
- Add 24 FPS to the persisted ASS Renderer frequency selector (Auto, 24, 30, 60, 120 FPS) in Player Settings → Subtitle settings.
- Include the beta27 diagnostics display fix for hostApiClassProbe, missingHostApiClassCount, dexHierarchy, dexTransitiveMissingDependencies, dexHierarchyScanErrors and dexObfuscatedSuperclassResolved in Manage Providers → Test class.
- Extension execution is not yet supported; Android build and device testing have not been performed.


---

## v1.4.9-beta34 — Aniyomi search diagnostic (development)
- New manually triggered extension search in Manage Providers with confirmation and result diagnostics.
- Flutter-to-Android search bridge; isolated classloader and bounded search results.
- No automatic source matching, episode lists or playable streams yet. Build/device verification pending.

## v1.4.9-beta33.1–beta33.4 — Aniyomi extension execution groundwork
- Confirmed isolated class loading and constructor ABI for 123Anime and AnimeOnsen.
- Added explicit instance creation test; resolved missing Kotlin runtime classes in release builds.
- User-reported Beta 33.4 diagnostics confirmed successful instance creation for both extensions.
- Search, episode retrieval and playback remained unverified.

## v1.4.9-beta32 — Isolated classloader investigation
- Diagnosed obfuscated superclass verification failures; added child-first loader and runtime/DEX diagnostics.
- User tests showed classes could be resolved using the isolated loader.

## v1.4.9-beta26 — ASS playback clock continuity
- Keep ASS animations advancing when player position notifications stop updating; distinguish fresh/stale reports and add counters for diagnosis.
- Extend Aniyomi DEX diagnostics to inspect obfuscated superclass chains and transitive host API dependencies, without executing extension code.
- No changes to native assrender or Aniyomi extension execution support.

# Beta19 (in progress)
- ASS texture polling changed to 50ms.
- Native libass alpha fix prepared separately; not integrated until new AAR import.
- Aniyomi extension diagnostics retained from beta18; executable support pending.

---

# v1.4.9 beta16–beta18 history

## beta18 (in progress)
- Native SurfaceTexture ASS rendering, no per-frame PNG transfers.
- Experimental Aniyomi extension diagnostics carried forward.
- 16:9 viewport alignment candidate fix committed; alpha/transparency requires further work and device testing.

## beta17
- More detailed Aniyomi APK class loading and DEX diagnostics.
- Device test: AnimeOnsen class load failed; AnimeSource host API unavailable.
- User screenshots showed ASS positioning and transparency regression relative to beta16.

## beta16
- User-provided visual baseline for ASS positioning and transparency.

---

# v1.4.9 beta2–beta15 changelog

# AnimeStream v1.4.9 beta2–beta15 — development notes

These notes document the experimental branches. A feature being present in source code does not mean it was verified on a device. The user confirmed that ASS subtitles work in beta15.

## beta15 — Working ASS subtitles (user verified)
- Imported an updated `assrender-release.aar` from the beta15 branch of `jepsefan/assrender`.
- Restricted the AAR import workflow to successful builds from that branch.
- Native libass diagnostics now count active events and log the first active style when a frame is empty.
- **Confirmed by user:** ASS subtitles now display correctly in beta15.
- Aniyomi APK execution is **not** fixed by this release.

## beta14 — Android font selection and AAR import preparation
- Updated `jepsefan/assrender` native libass initialization to use an accessible Android system font (Roboto, with Noto Sans fallback) and `ASS_FONTPROVIDER_NONE`.
- Added native logs identifying the font provider and chosen default font path.
- Updated the AnimeStream import workflow for the beta14 branch.
- These changes were experimental; beta15 is the first build in this sequence reported to display ASS subtitles successfully.

## beta13 — ASS timing diagnostics
- Added parsing of ASS Dialogue cue start/end times in the Flutter external subtitle overlay.
- Logged parsed cue counts, first/last timestamps, and the number of active cues when the native renderer returned an empty frame.
- Logs showed active cues while the native renderer returned no image; the issue remained unresolved in beta13.

## beta12 — ASS bridge/AAR integration iteration
- Updated the bundled native AAR, Android method-channel registration and AAR import workflow.
- Native loading was observed in testing, but ASS frames could still be empty even with parsed events.

## beta11 — External libass overlay introduced
- Integrated the Android `assrender` AAR and native `ExternalAssRenderer` method channel.
- Added a Flutter external ASS/SSA overlay for playback and related watch-screen integration.
- Added integration documentation and an AAR import workflow.
- This is separate from Better Player's internal subtitle renderer.

## beta10 — Provider extension diagnostics
- Updated Android host-side extension integration and the Manage Providers screen.
- Aniyomi APK execution remained experimental, not a supported playable source.

## beta9 — Provider/extractor iterations
- Updated Android extension handling, Manage Providers, Vidtube extraction, Anikoto, and source selection code.
- These changes do not establish that external Aniyomi APKs can execute.

## beta8 — Source and extractor iteration
- Updated Vidtube extraction and source-tile handling.

## beta7 — Aniyomi extension bridge iteration
- Updated Android activity, the Aniyomi extension bridge, and Manage Providers.
- APK discovery/inspection should not be confused with successfully loading and executing extension classes.

## beta6 — Provider and subtitle parsing iteration
- Updated AnimeOnsen, ASS parsing, subtitle parser registration, and Manage Providers.

## beta5 — Versioned provider test
- Advanced the beta version. No additional source-code change is shown in the comparison against beta4.

## beta4 — Android provider test iteration
- Updated Android manifest configuration and the beta version.

## beta3 — Manage Providers experiment
- Added Installed/Available provider management, refresh, local Dart-source download/storage/removal and error reporting.
- External provider execution was disabled; downloaded sources were not playable.
- Provider preferences received null/lifecycle handling improvements.
- This beta was based directly on the master baseline rather than beta2.

## beta2 — AniDB player experiment
- Updated Better Player integration and the watch/player path.
- AniDB playback remained experimental; this version is not a verified AniDB playback fix.

## beta1 — AniDB V1/V2/V3 experiment
- Reintroduced three AniDB test variants and source registration.
- Tested request headers, HEAD checks, and bounded Range GET/media signature diagnostics.
- AniDB playback was not confirmed working.

## Outstanding
- Aniyomi APK extensions can be detected but may report `missing_host_api` and `ClassNotFoundException`; they are not yet confirmed executable or playable.
- Further ASS rendering behavior across different subtitle files, fonts, and Android TV devices has not been comprehensively verified.

---

# v1.4.9-beta1 — AniDB playback experiment

Based on `v1.4.9` master. Reintroduces the AniDB V1/V2/V3 implementations and source registrations from the earlier beta30 test branch, without changing the Better Player fork or unrelated playback code. V1 uses Referer and HEAD diagnostics; V2 uses Referer, Origin and User-Agent; V3 adds a bounded HTTP Range GET probe to inspect media response status and MP4 signatures. This is a test release; AniDB playback remains unverified and may still fail.

---

# v1.4.9 Release Notes

This release is based on the `v1.4.8-beta23` application source, with version and documentation updates. It retains the subtitle/WebVTT, Android TV controls, SIMKL login/sync, AMOLED dimming, and experimental AniDB.se V1/V2/V3 features present in beta23. AniDB playback has not been confirmed working. Later beta24–beta30 code is intentionally excluded.

## v1.4.8 beta1–beta23 history

# v1.4.8-beta1

Original upstream notes: dub support for a source; retry for failed downloads; Windows/Linux playback fixes. The original notes warned that this was an experimental release.

---

# v1.4.8-beta2

- Baseline test build used for the custom BetterPlayer work.
- AnimeStream was switched to the writable **jepsefan/betterplayer-test** fork.
- BetterPlayer was pinned to a specific test commit.
- This beta did not yet include Stable Overlap, status-text positioning, or the Android TV Play/Pause changes.

Historical summary reconstructed from beta5 retrospective; original GitHub release reused beta1 notes.

### Android TV Amlogic decoder compatibility (beta2 test investigation)

On an **SDMC DV8919-KST (Telia Nordic STB, Android API 31)** using `OMX.amlogic.avc.decoder.awesome2` and Media3 `1.9.2`, migrating Better Player from Flutter `SurfaceTextureEntry` to `TextureRegistry.SurfaceProducer` correlated with a reproducible H.264 DASH playback failure at 1280×720:

| Rendering path | Required DPB | Allocated output buffers | Playback |
| --- | ---: | ---: | --- |
| SurfaceTextureEntry (working beta3 reference) | 8 | 14 | Works |
| SurfaceProducer (failing beta4 reference) | 23 | 21 | Fails |
| SurfaceProducer without `setSize()` | 23 | 21 | Fails |
| SurfaceTextureEntry restored (beta2 test build) | 8 | 14 | Works |

The failing decoder reported `Failed to provide requested picture buffers. (Got 21, requested 23)` and entered error state 2. Disabling `surfaceProducer.setSize()` alone did not fix it; fully restoring the SurfaceTextureEntry path did. The exact mechanism behind the DPB change remains unknown.

Relevant Better Player commits: last known working `54e1a2e`, SurfaceProducer migration `2849caa`, setSize-disabled test `41a12a3`, SurfaceTexture restoration `b214c1da`. AnimeStream dependency update: `563edfcd`; beta2 test build: `ab0c3aa`. This is a historical test finding, not a claim that all Amlogic devices are affected.

---

# v1.4.8-beta3

- Added the experimental **Stable Overlap** subtitle renderer.
- Added a runtime selector between **Default** and **Stable Overlap**.
- Added stable positioning for overlapping WebVTT cues.
- Added connected overlap-group handling so cues can reserve their positions for the lifetime of the group.
- Added experimental detection/left-side handling for status/UI subtitle groups with 5+ cues sharing the same start time; **left-side placement was not working correctly**.
- Fixed nullable subtitle-text handling.
- Began Android TV Play/Pause remote-control fixes.

Historical summary reconstructed from beta5 retrospective; original GitHub release reused beta1 notes.

---

# v1.4.8-beta4

- Carried forward the Stable Overlap subtitle work from beta3.
- Attempted left-side rendering for status/UI subtitle groups; **this did not work correctly in testing**.
- Attempted WebVTT continuation handling for text without repeated timestamps; **this did not work correctly in testing**.
- Made **Stable Overlap** the default subtitle renderer.
- Added further Android TV Play/Pause remote-control handling changes.
- Fixed a BetterPlayer WebVTT parser syntax error that blocked Android builds.
- Disabled Linux and Windows CI build jobs for the beta test workflow.

Historical summary reconstructed from beta5 retrospective; original GitHub release reused beta1 notes.

---

# v1.4.8-beta5

> Test release. The subtitle renderer changes are still experimental and may need further tuning on Android TV.

## v1.4.8-beta5

### Subtitle rendering
- Added the new **Stable Overlap** subtitle renderer.
- Stable Overlap is now the default subtitle renderer.
- Added a player-bar selector to switch between **Default** and **Stable Overlap** while a video is playing.
- Overlapping WebVTT cues are kept in stable positions so visible text does not jump when another cue appears or disappears.
- Connected overlapping cues are handled as one overlap group and preserve their original cue order.
- Experimental detection for status/UI subtitle groups with **5 or more cues sharing the same start time** was added in earlier betas.
- Reworked status/UI subtitles into a separate fixed left-side layer using explicit positioning.
- Fixed nullable subtitle text handling in the Stable Overlap renderer.

### WebVTT parsing
- Experimental WebVTT continuation parsing was added for text after blank lines without a repeated timestamp.
- Multi-line status cues are now rendered as one HTML block so continuation text such as **Attack / Defense / Magic / Speed** keeps its formatting and remains visible.
- Existing HTML subtitle formatting such as bold and italic text remains supported.

### Android TV controls
- Changed Android TV media-key handling so **Play/Pause** toggles playback instead of only pausing.
- Added explicit handling for **Play**, **Pause**, and **Space** playback keys.
- Moved media-key handling into the player's parent Focus tree so remote-control media keys can still be received when another player control has focus.
- Mapped Android TV **D-pad Right** to seek forward by the configured skip duration (10 seconds by default).
- Mapped Android TV **D-pad Left** to seek backward by the configured skip duration (10 seconds by default).

### Build and CI
- Includes the BetterPlayer WebVTT parser build fix introduced after beta4.
- Android-focused beta workflow; Linux and Windows CI builds remain disabled.

---

# v1.4.8-beta6

> Test release. This beta moves the subtitle fixes into AnimeStream's actual subtitle pipeline and adds D-pad seek animation.

## v1.4.8-beta6

## Changes since beta5

### Subtitle pipeline
- Moved the status/UI subtitle implementation into AnimeStream's actual **SubViewer** renderer.
- Reworked **VttRipper** so WebVTT cues are delimited by timestamps instead of blank lines.
- Continuation text such as **Attack / Defense / Magic / Speed** now stays attached to the same timed cue.
- Status/UI subtitles are rendered in a dedicated fixed left-side layer.

### Android TV D-pad seek
- **D-pad Right** seeks forward by the configured skip duration.
- **D-pad Left** seeks backward by the configured skip duration.
- D-pad seek now uses the same on-screen animation and skip counter as double-tap seek.

---


### Subtitle rendering
- Added the new **Stable Overlap** subtitle renderer.
- Stable Overlap is now the default subtitle renderer.
- Added a player-bar selector to switch between **Default** and **Stable Overlap** while a video is playing.
- Overlapping WebVTT cues are kept in stable positions so visible text does not jump when another cue appears or disappears.
- Connected overlapping cues are handled as one overlap group and preserve their original cue order.
- Experimental detection for status/UI subtitle groups with **5 or more cues sharing the same start time** was added in earlier betas.
- Reworked status/UI subtitles in AnimeStream's actual **SubViewer** renderer into a separate fixed left-side layer using explicit positioning.
- Fixed nullable subtitle text handling in the Stable Overlap renderer.

### WebVTT parsing
- Experimental WebVTT continuation parsing was added for text after blank lines without a repeated timestamp.
- Replaced blank-line-based VTT cue splitting in AnimeStream's **VttRipper** with timestamp-based cue boundaries so continuation text such as **Attack / Defense / Magic / Speed** remains part of the timed cue.
- Existing HTML subtitle formatting such as bold and italic text remains supported.

### Android TV controls
- Changed Android TV media-key handling so **Play/Pause** toggles playback instead of only pausing.
- Added explicit handling for **Play**, **Pause**, and **Space** playback keys.
- Moved media-key handling into the player's parent Focus tree so remote-control media keys can still be received when another player control has focus.
- Mapped Android TV **D-pad Right** to seek forward by the configured skip duration (10 seconds by default).
- Mapped Android TV **D-pad Left** to seek backward by the configured skip duration (10 seconds by default).
- D-pad seek now uses the same on-screen skip animation/counter as double-tap seek.

### Build and CI
- Includes the BetterPlayer WebVTT parser build fix introduced after beta4.
- Android-focused beta workflow; Linux and Windows CI builds remain disabled.

---

# v1.4.8-beta7

> Test release. This beta refines AnimeStream's subtitle pipeline and Android TV remote handling.

## v1.4.8-beta7

## Changes since beta6

### Subtitle fixes
- Removed keyword-based status/UI detection; only dense near-simultaneous cue groups are treated as status/UI now.
- VTT `\\h` spacing escapes are converted to normal spaces instead of being rendered literally.
- Removed empty lines inside parsed VTT cues so status text such as **Attack / Defense / Magic / Speed** does not consume excessive vertical space.
- Ignore ASS/SSA vector drawing commands such as `m 0 0 l 290 0 290 42 0 42` instead of displaying them as subtitle text.
- Increased status/UI cue grouping tolerance from **20 ms to 100 ms**, allowing cues such as 18:37.850 and 18:37.900 to stay in the same visual group.
- Added real configurable text alignment to `SubtitleText`; status/UI text now uses left alignment instead of being centered inside a left-positioned container.
- Increased the status/UI text area width to **62%** of the video width.

### Android TV controls
- Restored Play/Pause handling in the parent Android TV key handler.
- Keeps D-pad center/select available for navigating and activating player controls.
- Removed the old BetterPlayer **Subtitle renderer** button from AnimeStream because AnimeStream's visible subtitles are rendered by `SubViewer`, so that control was not connected to the active subtitle renderer.

---

# v1.4.8-beta8

> Test release. This beta adds safer status/UI subtitle grouping and Android TV focus navigation.

## Changes since beta7

### Subtitle status grouping
- Status/UI subtitles now use the area from 5% below the top to 5% above the bottom; oversized groups are scaled down to stay fully inside the video frame.
- Standalone status keywords such as **Attack**, **Defense**, **Magic**, **Speed**, **Equipment**, and **Skills** can identify a status/UI block.
- A keyword only triggers when it occupies a complete subtitle line by itself.
- When triggered, **all cues with the exact same start timestamp** are grouped together and rendered in the existing left-side status area.
- Embedded text such as `Monster: Raana` does not trigger this rule.

### Android TV controls
- Added a real focus target to the center **Play/Pause** control when player controls appear.
- When controls are visible, D-pad directions are left to Flutter focus navigation.
- When controls are hidden, the existing **Left/Right seek behavior and skip animation** are preserved.
- Existing Play/Pause media-key handling is unchanged.

---

# v1.4.8-beta9

> Test release. This beta adds SIMKL PIN/device-code login.

## Changes since beta8

### SIMKL login
- Added SIMKL device authorization using `POST /oauth2/device`.
- The account page shows the returned `user_code` and verification URL.
- Added an **Open Simkl** button using `verification_uri_complete` when available.
- The app polls `POST /oauth2/token` until authorization succeeds or the device code expires.
- Handles `authorization_pending`, `slow_down`, `expired_token`, and `access_denied`.
- The device flow uses `SIMKL_CLIENT_ID` and does not use the redirect URL flow for SIMKL login.
- Device authorization requests now use form-style OAuth parameters instead of JSON bodies.
- Cancel now stops the polling loop instead of leaving it running in the background.
- Expired device codes automatically request a new code.
- SIMKL device-flow errors are shown with specific messages and a retry option in the PIN dialog.
- Android TV D-pad directions no longer open the player overlay while it is hidden; Left/Right keep the existing ±skip seek, while D-pad center/OK opens the overlay.

---

# v1.4.8-beta10

> Test release focused on account sync, Android TV controls, updates, and playback defaults.

## Changes since beta9

### SIMKL watched progress
- Watching progress now enters the remote sync path when SIMKL is connected, instead of falling back to local-only storage just because AniList is not logged in.
- This fixes the beta9 case where SIMKL login worked but completed/watch progress was not sent to SIMKL.

### Android TV D-pad
- D-pad center / OK is now handled in the top-level Watch focus handler.
- When the player overlay is hidden, center / OK opens it directly.
- Hidden Left / Right keep the existing seek behavior and skip animation.
- Touch and mouse control behavior remains unchanged.

### UI defaults
- AMOLED Background is now enabled by default.
- Existing beta installs using the old default are migrated to AMOLED once.
- Users can still turn AMOLED Background off manually afterwards.

### Playback quality
- Preferred playback quality now defaults to **1080p**.
- Existing beta installs using the old 720p default are migrated to 1080p once.
- After that migration, users can still manually choose 720p or another quality without it being forced back to 1080p.

### AniList TV login
- Android TV now offers a local-network QR login option for AniList.
- The QR code opens a temporary HTTP page hosted directly by the TV on its LAN IP.
- The phone opens AniList Auth Pin login, then the returned access token can be pasted into the local page and sent directly to the TV.
- The QR code contains only the TV's temporary local login URL and session ID, never the AniList token itself.
- The TV validates the received token before saving it.
- Android TV also keeps a **Use old login** option for the existing redirect-based flow.
- Phones and tablets continue to use the existing AniList login flow directly without showing the QR screen.
- This requires a separate `ANILIST_PIN_CLIENT_ID` whose AniList Redirect URL is `https://anilist.co/api/v2/oauth/pin`.

---

# v1.4.8-beta11

> Test release focused on parallel installation, SIMKL login, and OLED pause protection.

## Changes since beta10

### Separate Android test app
- The fork now uses Android application ID `app.animestream.test`.
- It can be installed alongside the normal AnimeStream app instead of Android treating it as an update to `app.animestream`.

### SIMKL login
- SIMKL device login now validates the returned access token before reporting a successful login.
- SIMKL profile parsing accepts the alternate user ID locations returned by different API responses.
- SIMKL sync operations are now awaited so sync failures are no longer detached from the caller.
- The SIMKL login dialog now shows a QR code.
- The QR target includes the PIN, using SIMKL's complete verification URL when supplied and `https://simkl.com/pin/<PIN>` as the fallback.
- Manual PIN entry and the Open Simkl button remain available.

### OLED pause protection
- When playback has been paused continuously for 8 seconds, a dark overlay fades over the video.
- The player controls stay above the dimming layer and remain readable.
- The dimming is removed immediately when playback resumes.
- This does not change the device's system brightness.

### MAL
- No MAL QR/device-flow change is included in beta11.
- The existing MAL login remains the browser-based OAuth2/PKCE flow.

---

# v1.4.8-beta12

> Test release focused on fixing SIMKL login validation.

## Changes since beta11

### SIMKL login
- Fixed the post-login validation request to use GET for `/users/settings`.
- Fixed the normal SIMKL profile request to use GET for `/users/settings`.
- This addresses the 403 error shown after approving the SIMKL PIN login even though SIMKL had already returned an access token.

### Included from beta11
- Separate Android application ID `app.animestream.test` for parallel installation.
- SIMKL QR/PIN login.
- OLED pause dimming after 8 seconds.
- Android TV info-page focus improvements.
- AniList local-network QR login remains available.

---

# v1.4.8-beta13

> Test release focused on global AMOLED inactivity protection.

## Changes since beta12

### AMOLED inactivity dimming
- When **AMOLED Background** is enabled, the whole AnimeStream interface dims after 60 seconds without user input.
- The 60-second dimming is disabled when **AMOLED Background** is turned off.
- D-pad/key input, touch, pointer movement, hover, and scroll activity reset the timer.
- The dim layer fades in and out and does not change the device's system brightness.
- Returning to the app resets the inactivity timer.
- The player's shorter pause-specific dimming remains separate.

---

# v1.4.8-beta14

> Test release focused on Android TV navigation, AMOLED protection, SIMKL V2 permissions, and updated app branding.

## Changes since beta13

### Global AMOLED inactivity dimming
- When **AMOLED Background** is enabled, AnimeStream dims after 60 seconds without input.
- The 60-second global dimming is disabled while the full-screen player page is open.
- The player's own pause-specific OLED dimming remains separate.
- Keyboard/D-pad, touch, pointer movement, hover, and scroll reset the inactivity timer.

### Android TV player timeline
- The timeline no longer gives D-pad focus directly to the Slider widget.
- A dedicated focus wrapper now handles TV navigation while keeping the timeline glow visible.
- Left / Right seek while the timeline is focused.
- Down moves focus to the lower player controls such as quality, servers, episode list, speed, subtitles, and audio.
- Up moves focus back to the center Play/Pause control.

### SIMKL Auth V2
- SIMKL device authorization now requests both `media:read` and `media:write`.
- This allows the V2 authorization flow to request permission to update the user's media library.
- When SIMKL returns a scope field with the token response, AnimeStream checks that `media:write` was granted.
- Token validation and profile loading continue to use the authenticated SIMKL account.

### Android TV launcher
- Added Android TV Leanback launcher support.
- The app now uses a dedicated purple/magenta AnimeStream banner for the Android TV launcher tile.
- The TV banner remains separate from the mobile launcher icon.

### Mobile app icon
- The Android mobile launcher icon now uses the purple/magenta AnimeStream symbol without the wordmark.
- The adaptive icon uses a black background with the purple symbol.
- The Android TV banner remains unchanged and continues to use the wide branded tile.

---

# v1.4.8-beta15

> Test release focused on Android launcher icon behavior.

## Changes since beta14

### Android launcher icon
- The purple AnimeStream icon now uses the standard adaptive launcher resource `@mipmap/ic_launcher`.
- Android can now apply the same launcher mask/shape behavior as the previous green icon.
- The purple symbol remains the foreground artwork on a black adaptive-icon background.

---

# v1.4.8-beta16

> Diagnostic test release focused on the AniList-to-SIMKL ID lookup.

## Changes since beta15

### SIMKL lookup diagnostics
- Added detailed APP-log output for the SIMKL anime search used to resolve an AniList anime to a SIMKL ID.
- Logs the AniList lookup query, HTTP status code, SIMKL response body, result count, and resolved SIMKL ID.
- Non-2xx search responses now include the HTTP status and response body in the thrown error.
- Unexpected SIMKL search response formats are logged explicitly.

### Purpose
- Helps diagnose why AnimeStream can sync AniList and MAL while SIMKL is missing from the SyncHandler list.
- Does not change the SIMKL V2 login or watch-history sync behavior.

---

# v1.4.8-beta17

> Test release fixing authenticated AniList-to-SIMKL ID lookup.

## Changes since beta16

### SIMKL authenticated lookup
- SIMKL anime search requests now include the saved SIMKL access token when available.
- SIMKL anime info requests use the same authenticated headers.
- Sends `Authorization: Bearer <token>`, `simkl-api-key`, and `Accept: application/json`.
- Keeps the beta16 lookup diagnostics so HTTP status, response data, result count, and resolved SIMKL ID remain visible in the APP log.
- Access tokens are never written to the log.

### Why
- Beta16 confirmed SIMKL returned HTTP 401 `user_token_required` because this client ID requires a user access token on every request.
- This allows the existing AnimeStream flow to resolve AniList ID -> SIMKL ID before SyncHandler updates SIMKL watch progress.

---

# v1.4.8-beta18

> Test release using MyAnimeList as the primary external-ID lookup for SIMKL.

## Changes since beta17

### MAL -> SIMKL lookup test
- When AniList is the active database, AnimeStream now reads the existing MAL ID from the AniList info result first.
- SIMKL lookup is performed with `https://myanimelist.net/anime/<malId>` instead of the AniList URL in this beta.
- The APP log explicitly shows that MAL is being used as the SIMKL lookup source.
- Logs the MAL URL, result count, and resolved SIMKL ID.
- If no MAL ID is available, the log states that the SIMKL lookup was skipped.

### Intended follow-up behavior
- Beta18 is deliberately MAL-first so the MAL -> SIMKL mapping can be tested independently.
- After this path is verified, the intended normal behavior is AniList -> SIMKL first, then MAL -> SIMKL only when the AniList lookup returns zero results.

---

# v1.4.8-beta19

> SIMKL external-ID lookup now uses AniList first with MyAnimeList as fallback.

## Changes since beta18

### AniList -> SIMKL primary lookup
- When AniList is the active database, AnimeStream first searches SIMKL using `https://anilist.co/anime/<id>`.
- The APP log explicitly shows that AniList is being used as the primary SIMKL lookup source.

### MAL -> SIMKL fallback
- If the AniList lookup succeeds but returns `results=0`, AnimeStream reads the MAL ID already provided by AniList.
- It then retries SIMKL lookup with `https://myanimelist.net/anime/<malId>`.
- The APP log shows when the fallback is triggered, the MAL URL used, the result count, and the resolved SIMKL ID.
- If no MAL ID exists, the log states that the fallback was skipped.

### Logging
- Keeps the authenticated SIMKL request diagnostics from beta16/beta17.
- Typical successful fallback sequence:
  `AniList -> SIMKL results=0`
  `AniList results=0 -> MAL fallback`
  `MAL -> SIMKL results=1`
  `resolved simklId=...`

### VTT stacked subtitle colors
- Added visual separation for overlapping VTT cues in the normal bottom subtitle stack.
- The newest/bottom cue is white.
- The cue above it is light gray (`#D0D0D0`).
- Older cues use gray (`#9E9E9E`).
- This only affects VTT cues in bottom-aligned groups; status/UI cues and ASS rendering keep their existing behavior.

---

# v1.4.8-beta20

> Subtitle cleanup and VTT overlap-color test release.

## Changes since beta19

### VTT empty-row cleanup
- VTT dialogue lines are now cleaned before they are added to a cue.
- `\\h`, repeated `\\h`, HTML/VTT tags, and surrounding whitespace are removed before deciding whether a line is empty.
- Lines that become empty after cleanup are skipped instead of creating visible blank rows.
- A second cleanup is performed when the cue is finalized, so fully empty cues are not created.
- This is intended to make the status/UI subtitle block behave consistently on mobile and Android TV.

### VTT overlapping cue colors
- Bottom-aligned VTT cues now cycle through three text colors by cue order:
  - white
  - light gray (`#D0D0D0`)
  - gray (`#9E9E9E`)
  - then repeat white -> light gray -> gray
- A single cue therefore uses white.
- This replaces the beta19 behavior where all cues older than the second one were gray.
- The color cycling only applies to normal bottom-aligned VTT cues. Status/UI cues and ASS rendering keep their existing behavior.

### SIMKL lookup
- Keeps the beta19 AniList -> SIMKL primary lookup with MAL -> SIMKL fallback when AniList returns zero results.

---

# v1.4.8-beta21

> Adds optional multi-color VTT cue styling.

## Changes since beta20

### VTT cue color cycle
- Bottom-aligned VTT cues now cycle through four colors:
  - white
  - gray (`#9E9E9E`)
  - light yellow (`#CCBF51`) with a black stroke
  - green (`#53FB57`) with a black stroke and black background
  - then repeat from white
- A single cue starts as white.
- Status/UI cues to the left are not part of this color cycle.

### Subtitle setting
- Added a new `VTT cue colors` toggle in Subtitle Settings.
- The setting is enabled by default, including for existing installs that do not yet have the saved value.
- Turning it off restores the normal configured subtitle text/stroke/background colors instead of using the cue color cycle.

### VTT cleanup
- Keeps the beta20 cleanup that removes empty, whitespace-only, tag-only, and `\\h`-only rows before they can create visible blank subtitle lines.

### SIMKL lookup
- Keeps the beta19 AniList -> SIMKL primary lookup with MAL -> SIMKL fallback when AniList returns zero results.

---

# v1.4.8-beta22

> Locks VTT cue colors so visible subtitles do not change color when another cue ends.

## Changes since beta21

### Locked VTT cue colors
- Each normal bottom-aligned VTT cue gets a color slot the first time it is shown.
- That cue keeps the same color for its lifetime, even if an older overlapping cue disappears.
- New colorized cues continue the four-color sequence instead of recalculating colors from the current visible stack.
- Status/UI cues shown on the left do not consume a color slot.

### VTT cue color cycle
- The enabled cue-color sequence remains:
  - white
  - gray (`#9E9E9E`)
  - light yellow (`#CCBF51`) with black stroke
  - green (`#53FB57`) with black stroke
  - then repeat from white
- Green no longer forces a black background.

### Subtitle setting
- Keeps the `VTT cue colors` toggle from beta21.
- It remains enabled by default.
- Turning it off restores the configured normal subtitle colors.

### VTT cleanup
- Keeps the beta20 cleanup for empty, whitespace-only, tag-only, and `\\h`-only rows.

### SIMKL lookup
- Keeps the AniList -> SIMKL primary lookup with MAL -> SIMKL fallback.

### AniDB provider
- Updated the AniDB source base URL from `https://anidb.app` to `https://anidb.se`.

---

# v1.4.8-beta23

> Experimental AniDB.se provider rebuild with three independently selectable variants.

## Changes since beta22

### AniDB.se provider variants
- Rebuilt the AniDB provider around the new `anidb.se` site structure instead of the old `anidb.app` frontend API.
- Added three separate built-in test sources so they can be compared independently:
  - `AniDB.se v1` — root-site search using `/?s=<title>`.
  - `AniDB.se v2` — `/anime/` archive search using the same `s` parameter.
  - `AniDB.se v3` — direct English-title slug lookup, for URLs such as `/anime/the-exiled-heavy-knight-knows-how-to-game-the-system/`.
- Search results now keep the full anime URL as the provider alias instead of trying to extract the old numeric AniDB.app ID.

### Episode discovery
- Anime pages are parsed for episode links directly from HTML.
- Episode numbers are detected from link text or URLs containing `episode` / `ep`.
- Provider logs now show the anime page and number of episodes detected.

### Stream discovery
- Episode pages are inspected for direct `.m3u8` URLs, common `file` / `source` script assignments, video/source tags and iframe/embed pages.
- The provider follows one level of iframe/embed pages while looking for a playable HLS stream.
- Logs show the selected variant, episode page and number of streams found.

### Safer source search
- Empty provider searches no longer cause `RangeError ... valid value range is empty: 0` from `match[0]`.
- The app now reports a normal no-results error instead, making source testing easier.

### Existing beta22 changes kept
- VTT cue colors remain locked to each cue while it is tracked.
- Green VTT cue styling has black stroke without a forced black background.
- The VTT cue-colors toggle remains enabled by default.

---

## Later experiments (not included in v1.4.9)

### v1.4.8-beta24
AniDB episode placeholder href and stream discovery experiments.

### v1.4.8-beta25
No separate published beta25 release found; development/planning notes exist.

### v1.4.8-beta26
AniDB selected-series filtering and HTTP/canonical episode verification.

### v1.4.8-beta27
AniDB episode discovery variants and validation; playback unverified.

### v1.4.8-beta28
AniDB stream extraction variants; playback unverified.

### v1.4.8-beta29
AniDB exact-series episode matching and HEAD diagnostics; playback still stalled.

### v1.4.8-beta30
AniDB header comparisons and Range GET diagnostics; playback still stalled.

