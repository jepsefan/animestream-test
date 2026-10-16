# AnimeStream — Latest three beta releases

The complete development history is in [CHANGELOG.md](CHANGELOG.md). Notes below reflect the current beta34.47 development branch.

## v1.4.9-beta34.47 — Lazy video links
- Add fallback from Anikku's modern `resolveVideo` to older `getVideoUrl` for compatible extension-hosted video placeholders.
- Preserve audio/subtitle tracks and headers; don't issue extra requests for already playable URLs.
- AnimeOnsen search fallback, built-in providers and subtitle renderer unchanged.
- Build/device regression testing required.

## v1.4.9-beta34.46 — Anikku Hoster compatibility
- Add common Hoster request and parser entry points for compatible Anikku extensions.
- Support legacy per-video URL retrieval methods without changing existing playable streams.
- Legacy extensions continue using their episode-based video extraction, without additional hoster HTTP requests.
- Beta34.45 fallback search and current subtitle/player handling unchanged. **Build and device tests pending.**

### Known limitations
- Some non-Latin subtitles (possibly Arabic) appear as squares with crosses; logged and deliberately deferred per user request.
- **Deferred subtitle display bug:** A language that appears to be Arabic is rendered as square boxes with crosses during AnimeOnsen playback; language identification and font/glyph root cause are unconfirmed. This is recorded only, not fixed in beta34.43.
### Known limitations
- Some 123Anime video hosts still return no playable streams.
- Full Anikku Host API coverage, source preference screens and standalone external audio playback remain unfinished.
- Installing extension APKs still requires Android confirmation and cryptographic signing-certificate checks; repository URLs are entered by the user and stored locally.

Older betas: [CHANGELOG.md](CHANGELOG.md).
