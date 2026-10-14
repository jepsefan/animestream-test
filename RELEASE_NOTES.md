# AnimeStream — latest three beta releases

Only the three latest beta versions are kept here. Older entries are archived in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.17 — Remove retired AniDB sources (build validation pending)
- Remove built-in AniDB V1, V2 and V3 from the source selector.
- Delete the obsolete AniDB web scraping and video extraction implementation.
- Remove all AniDB V1/V2/V3 and legacy V3 alias registrations and the unused import.
- Existing AniList metadata integration, ordinary providers and Aniyomi extensions remain untouched.
- If AniDB was previously selected, the existing missing-provider fallback selects another available provider.
- Build and device validation pending.

## v1.4.9-beta34.16 — Aniyomi extensions on series pages (build/device testing pending)
- Register installed Android Aniyomi APK sources directly in AnimeStream's normal source dropdown, identified by [Ext].
- Use original extension search, episode list and stream resolution through a Flutter/Android bridge.
- Auto-select only an unambiguous exact title or a high-confidence alternate title verified against the exact AniList series ID; otherwise use Manual Search.
- Persist manual source selections per AniList series and per installed extension without overwriting other sources.
- Show available source-provided episode thumbnails and pass video URL, quality, selected subtitle and request headers to the existing player workflow.
- Downloads through external extensions are disabled; unchanged native sources remain available.
- No playback for Android TV or any particular extension has been verified. Beta API support still varies by extension. Multiple audio/subtitle tracks and advanced hoster APIs are not yet integrated.

## v1.4.9-beta34.15 — Cache-aware stream stage inspection (unverified)
- For Test streams, use an application-level OkHttp interceptor so cached requests are recorded as well as network responses.
- For 123Anime, report server-tab count and safe presence/shape of episode-info target fields, without logging embed URLs, tokens, cookies, request query strings or media URLs.
- Show HTTP status, stage, cache flag and structural JSON information in stream diagnostics to distinguish empty metadata from unreachable player requests.
- No changes to stream routing, playback, or the successful AnimeOnsen extraction flow; build and device validation required.
