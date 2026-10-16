# AnimeStream — Latest three beta releases

The complete development history is in [CHANGELOG.md](CHANGELOG.md). Notes below reflect the current beta34.43 development branch.

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

## v1.4.9-beta34.41 — Parsed source compatibility
- Add the shared `ParsedAnimeHttpSource` superclass and Jsoup parsers for anime, episode and stream metadata.
- Extend Anikku HTTP source parsing and sorting hooks.
- Repair the missing base class needed by Yūzōnō's Animenosub extension.
- **User confirmed Animenosub [Ext] search, episodes, SUB/DUB/RAW video choices and actual Better Player playback.** AnimeOnsen [Ext] also remained functional.

### Known limitations
- **Deferred subtitle display bug:** A language that appears to be Arabic is rendered as square boxes with crosses during AnimeOnsen playback; language identification and font/glyph root cause are unconfirmed. This is recorded only, not fixed in beta34.43.
### Known limitations
- Some 123Anime video hosts still return no playable streams.
- Full Anikku Host API coverage, source preference screens and standalone external audio playback remain unfinished.
- Installing extension APKs still requires Android confirmation and cryptographic signing-certificate checks; repository URLs are entered by the user and stored locally.

Older betas: [CHANGELOG.md](CHANGELOG.md).
