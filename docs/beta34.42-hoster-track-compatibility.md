# Beta34.42 — Hoster and lazy video compatibility

Base: beta34.41 (the user-verified reference with AnimeOnsen and Animenosub playback).

- Adds `AnimeHttpSource.resolveVideo(Video)` with upstream-style passthrough default for extension ABI compatibility.
- The generic extension bridge tries `resolveVideo` only for non-HTTP/HTTPS placeholder video URLs; it preserves already-playable HTTP/HTTPS URLs untouched.
- Hoster failures are isolated: one failing hoster does not stop other hosters from providing streams. If all attempts fail and no videos are returned, the last underlying error is preserved for diagnostics.
- Existing subtitle/audio track data on returned Video objects remains intact, including on video objects returned by a source's resolver.
- Build version: `1.4.9-beta34.42+53`.

This release does NOT yet add an audio track selector to Better Player; the host bridge currently reports audio track count but does not expose all external audio track URLs to playback UI. No APK/Gradle build or device regression tests performed in this environment.

Regression test: build APK; verify AnimeOnsen and Animenosub searches, episode lists and actual playback; test extension with multiple hosters where one fails; inspect stream count and subtitle information; report redacted diagnostics.
