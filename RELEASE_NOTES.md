# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.88, beta34.87 and beta34.86.

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
- Widen the 18+ circle opening without moving its plus sign or changing icon size.
- Add open-ring 18+ symbol matching the selected artwork, at full 55px height next to the Watch/Info button and a smaller overlay on search, Related, and Recommended cards. Propagate AniList adult classification through search, information, and related metadata; use provider NSFW flags where available. The icon appears only when global 18+ is enabled and the specific title is classified adult.
- Metadata search uses exactly one provider: AniList when enabled, otherwise the first enabled MAL/Kitsu backup. Empty results and failures never cascade to another source. The 18+ switch now controls MAL `nsfw` requests and Kitsu local NSFW filtering.
- AniList search and extension AniList matching now respect the 18+ metadata setting: adult content remains excluded by default; enabling it removes the `isAdult: false` GraphQL filter. Search input is safely JSON-escaped.
- Added an off-by-default global 18+ content switch at the bottom of Metadata in Built-in providers. It hides APKs officially marked NSFW in the source picker and guards stream access. On change, it synchronizes unambiguously named on/off adult settings from approved extension sources only. Incompatible sources are skipped; no invented extension settings or changes to AniList/MAL/SIMKL tracking.
- Source settings gear added directly to Manage Providers > Installed and the nested Installed extension catalog, including apps installed outside catalogs. Available now defaults to Installed when APK extensions exist and Browse otherwise; manual tab choice is respected.
- Installed extensions now have a Source settings page exposing their actual Aniyomi/Anikku preference options: list, on/off, multiple choice, and non-sensitive text fields for source domains.
- Preferences are stored locally per extension source and cached source instances are refreshed after saving; unsupported extensions show a clear message.
- No change to BetterPlayer, audio, subtitles, or existing stream selection.
- Version `1.4.9-beta34.86+112`. APK build/device tests not yet run.
