# Beta34.47 — Generic legacy lazy video resolution

Base: beta34.46, whose build and playback were confirmed by the user.

- The shared ExtensionSourceCalls pipeline now tries `resolveVideo(Video)` first for non-playable video placeholders.
- If the video remains unresolved, its `videoPageUrl` is valid HTTP(S), and the extension supplies a legacy URL resolver, it then tries `getVideoUrl(Video)` from beta34.46. The shared default parser is not treated as proof of an extension-specific resolver.
- Successful legacy results use `Video.copy(videoUrl = ...)`, retaining media request headers, external subtitle/audio tracks and quality labels.
- Direct playable HTTP(S) URLs bypass both resolution paths.
- A missing, rejected or failing lazy resolver keeps the previous candidate for normal sanitized diagnostics.
- No change to AnimeOnsen's HTTP 403 search fallback, the extension installer, Better Player or subtitle rendering.
- Version: `1.4.9-beta34.47+58`.

**Verification:** Source committed, not Flutter/Gradle build tested or device tested here. Verify AnimeOnsen [Ext] search, episodes, playback and its nine subtitle entries; Animenosub [Ext] playback; and another extension returning a placeholder URL with a valid video page. Confirm the selected subtitles and stream headers are still retained.

**Known issue deferred by user:** some possibly Arabic subtitles display boxes with crosses. No font/rendering changes were made.
