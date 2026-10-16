# AnimeStream — Latest three beta releases

The complete development history is in [CHANGELOG.md](CHANGELOG.md). Notes below reflect the current beta34.45 development branch.

## v1.4.9-beta34.45 — AnimeOnsen extension 403 search fallback
- Detect HTTP 403 on the installed AnimeOnsen extension's Meilisearch endpoint, and only in that case search using the already-working built-in AnimeOnsen v4 API.
- Preserve title identity via the shared AnimeOnsen content ID, then continue episode retrieval, video resolution and subtitle handling in AnimeOnsen [Ext].
- Show fallback status in Manage Providers diagnostics, without exposing tokens.
- Built-in AnimeOnsen and other extensions unchanged. **Not yet build/device verified.**
- Keep deferred non-Latin subtitle glyph issue unchanged.

## v1.4.9-beta34.44 — Configure extension source preferences
- **Source settings** in Manage Providers for approved `[Ext]` sources, using each extension's own declared settings.
- Support selectable lists and on/off controls, with bounded options and validated updates stored in source-specific Android preferences.
- Animenosub's declared video quality, SUB/RAW and preferred video server options are primary test cases.
- Does not change the player, subtitle renderer or external audio playback.
- **Not yet built or device-tested.** Beta34.43 remains the latest version with user-confirmed playback.

### Known limitations
- Some non-Latin subtitles (possibly Arabic) appear as squares with crosses; logged and deliberately deferred per user request.
- **Deferred subtitle display bug:** A language that appears to be Arabic is rendered as square boxes with crosses during AnimeOnsen playback; language identification and font/glyph root cause are unconfirmed. This is recorded only, not fixed in beta34.43.
### Known limitations
- Some 123Anime video hosts still return no playable streams.
- Full Anikku Host API coverage, source preference screens and standalone external audio playback remain unfinished.
- Installing extension APKs still requires Android confirmation and cryptographic signing-certificate checks; repository URLs are entered by the user and stored locally.

Older betas: [CHANGELOG.md](CHANGELOG.md).
