# AnimeStream — Latest three beta releases

The complete development history is in [CHANGELOG.md](CHANGELOG.md). Notes below reflect the current beta34.44 development branch.

## v1.4.9-beta34.44 — Configure extension source preferences
- **Source settings** in Manage Providers for approved `[Ext]` sources, using each extension's own declared settings.
- Support selectable lists and on/off controls, with bounded options and validated updates stored in source-specific Android preferences.
- Animenosub's declared video quality, SUB/RAW and preferred video server options are primary test cases.
- Does not change the player, subtitle renderer or external audio playback.
- **Not yet built or device-tested.** Beta34.43 remains the latest version with user-confirmed playback.

## v1.4.9-beta34.43 — External extension audio metadata
- Preserve external audio track URLs, language and labels from Anikku extensions into AnimeStream's playback-only stream data.
- Show counts of external subtitle and audio tracks in the server selector.
- External standalone audio tracks are **not yet selectable or playable** through Better Player. HLS/internal player track selection is unchanged.
- **User-confirmed on-device:** AnimeOnsen [Ext] plays video in beta34.43 and 9 subtitle tracks are displayed. This confirms track discovery, not that every individual track was rendered or selected. Other extension regression tests remain open.

## v1.4.9-beta34.42 — Hoster and lazy video support
- Add the Anikku-compatible `resolveVideo(Video)` hook for extension implementations resolving a playable URL at a later stage.
- Continue trying remaining hosters if an individual hoster fails; leave valid HTTP/HTTPS streams unchanged.
- Preserve subtitle and audio metadata from returned video objects.
- **User confirmed video playback working in beta34.42.**

### Known limitations
- Some non-Latin subtitles (possibly Arabic) appear as squares with crosses; logged and deliberately deferred per user request.
- **Deferred subtitle display bug:** A language that appears to be Arabic is rendered as square boxes with crosses during AnimeOnsen playback; language identification and font/glyph root cause are unconfirmed. This is recorded only, not fixed in beta34.43.
### Known limitations
- Some 123Anime video hosts still return no playable streams.
- Full Anikku Host API coverage, source preference screens and standalone external audio playback remain unfinished.
- Installing extension APKs still requires Android confirmation and cryptographic signing-certificate checks; repository URLs are entered by the user and stored locally.

Older betas: [CHANGELOG.md](CHANGELOG.md).
