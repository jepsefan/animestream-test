# Beta25 – AniDB episode URL handling (in development)

> Planned changes on branch `beta25-anidb-episodes`. These are **not yet implemented or verified**. The current app version remains unchanged.

### In-app AniDB test sources (not yet build-tested)
- Added three selectable built-in providers: **AniDB V1**, **AniDB V2**, and **AniDB V3**.
- V1 uses generated episode URLs and does not require a media indicator to list an episode.
- V2 validates episode pages for media indicators and can use valid page links.
- V3 currently shares V2's verification behavior; its fallback stream strategy is not implemented yet.
- Legacy AniDB identifier maps to V3 for compatibility.

### Implemented in source (not yet build-tested)
- Replaced the retired anidb.app JSON API with an initial anidb.se HTML provider for search, episode discovery, and direct media URL extraction.
- Episode candidates are constructed from anime slug and episode number; only pages with media indicators are listed.
- Embedded iframe players are not yet resolved, and live site behavior has not been verified.

### Intended behavior / pending validation
- Read episode numbers from the anime series page rather than trusting placeholder `href="#"` links.
- Construct candidate episode URLs from the series slug and episode number, following `https://anidb.se/<anime-slug>-episode-<number>-english-subbed/`.
- Prefer a valid episode link provided by the site when one exists; use constructed URLs when links are missing or placeholders.
- Show only episodes confirmed as published, excluding future or unavailable episodes without renumbering the remaining entries.
- Treat network errors separately from confirmed missing episodes to avoid hiding available content.
- Keep episode-page stream/embed extraction as a separate step and preserve existing provider functionality.

### Provider migration (required)
- Remove all reliance on the discontinued `anidb.app` API, including search, episode-list and stream endpoints.
- Implement HTML-based search, episode discovery and episode-page stream extraction for `anidb.se`.
- Validate published episodes before displaying them; do not treat network errors as proof that episodes are unavailable.
- The current `master` AniDB provider still uses the old JSON API. This migration is required and is **not yet implemented or tested**.
- No beta25 APK or release has been published yet.

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

## Previous betas

### v1.4.8-beta4
- Carried forward the Stable Overlap subtitle work from beta3.
- Attempted left-side rendering for status/UI subtitle groups; **this did not work correctly in testing**.
- Attempted WebVTT continuation handling for text without repeated timestamps; **this did not work correctly in testing**.
- Made **Stable Overlap** the default subtitle renderer.
- Added further Android TV Play/Pause remote-control handling changes.
- Fixed a BetterPlayer WebVTT parser syntax error that blocked Android builds.
- Disabled Linux and Windows CI build jobs for the beta test workflow.

### v1.4.8-beta3
- Added the experimental **Stable Overlap** subtitle renderer.
- Added a runtime selector between **Default** and **Stable Overlap**.
- Added stable positioning for overlapping WebVTT cues.
- Added connected overlap-group handling so cues can reserve their positions for the lifetime of the group.
- Added experimental detection/left-side handling for status/UI subtitle groups with 5+ cues sharing the same start time; **left-side placement was not working correctly**.
- Fixed nullable subtitle-text handling.
- Began Android TV Play/Pause remote-control fixes.

### v1.4.8-beta2
- Baseline test build used for the custom BetterPlayer work.
- AnimeStream was switched to the writable **jepsefan/betterplayer-test** fork.
- BetterPlayer was pinned to a specific test commit.
- This beta did not yet include Stable Overlap, status-text positioning, or the Android TV Play/Pause changes.

### Earlier v1.4.8 beta notes
The repository previously carried the original beta notes:
- Dub support for a source.
- Added retry option for failed downloads.
- Fixed playback issues on Windows/Linux.
