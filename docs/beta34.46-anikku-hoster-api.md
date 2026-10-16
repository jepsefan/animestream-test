# AnimeStream beta34.46 — Anikku Hoster compatibility

Base: user-confirmed beta34.45, including the AnimeOnsen [Ext] HTTP 403 search fallback.

Changes:
- Shared AnimeHttpSource adds Anikku-style hosterListRequest, videoListRequest(Hoster), videoListParse(Response, Hoster), getHosterList and getVideoList(Hoster) hooks.
- Adds legacy fetchVideoUrl, getVideoUrl and videoUrlRequest hooks.
- Avoids attempting modern hoster network fetch for legacy episode-only source implementations that do not supply a hoster list parser.
- Existing Hoster failure isolation and lazy resolveVideo handling remain in ExtensionSourceCalls.
- No changes to Better Player, subtitle rendering, the local extension catalogue, or search fallbacks.

Version: 1.4.9-beta34.46+57.

**Not build- or device-verified.** Regression tests: AnimeOnsen [Ext] search through 403 fallback, episodes, playback and nine subtitles; Animenosub [Ext] search and playable SUB/DUB/RAW; source settings in beta34.44; another extension that implements the modern Hoster API. Record any missing class/method error without exposing signed URLs or credentials.

Known issue intentionally deferred: some possibly Arabic subtitles appear as squares with crosses.
