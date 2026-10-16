# beta34.51 — Extension episode recovery and safe error stages

Base: beta34.50, which introduced Yūzōnō multi-select preferences.

## Changes
- A previously confirmed [Ext] source match is tried only once during an episode-page load. On failure or an empty episode list, the normal title-search flow continues.
- Track whether a source failed in `source_search`, `title_matching`, or `episode_fetch` and count bounded attempts. Diagnostics use exception type names, not error text or source URLs.
- Manual Search differentiates a source exception from a genuine empty result.
- Native source preference setup wraps loading and screen construction in named failure stages; Flutter shows sanitized error type/category and missing class identifiers, if present.
- Existing video handling, AnimeOnsen HTTP 403 fallback, subtitle rendering and user-approved extension activation are not modified.

## Test
Build v1.4.9-beta34.51+62. For a previously saved extension match, test both a valid title and a stale title link. Verify ordinary search runs after a stale link rather than repeating it for every title variant. On a failing extension, inspect the source status and Source settings error stage. Verify Animenosub playback when the remote source is available. Do not treat a site's HTTP error as an APK class-loading failure.

**Not independently built or device-tested.** Known deferred subtitle missing-glyph issue remains unchanged.
