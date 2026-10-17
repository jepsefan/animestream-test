# AnimeStream — Latest three beta development versions

The complete development history is in [CHANGELOG.md](CHANGELOG.md). These notes describe beta34.55, beta34.54 and beta34.53. Beta34.54 did not produce a verified APK.

## v1.4.9-beta34.55 — Fix Dart compilation of Aniyomi hoster labels
- Restore a complete Dart `RegExp` for structured quality/hoster labels and correct the interrupted `getStreams()` implementation.
- Remove accidentally duplicated Dart code outside the provider class; this addresses the reported compilation cascade in `aniyomiExtensionProvider.dart`, `sources.dart` and `infoProvider.dart`.
- Preserve meaningful server/hoster names, video quality, URLs, request headers and subtitle/audio track metadata. Continue excluding placeholder `no_hoster_list`.
- Version `1.4.9-beta34.55+65`. **User-confirmed on device:** AniWaves.ru [Ext] finds the title, lists DatSaV (360p/480p) and Vidplay (720p), and plays video successfully. This verifies the tested extension playback path; other hosts and settings remain untested, and CI build status has not been checked independently.

## v1.4.9-beta34.54 — Build-fix attempts (not successful)
- Beta34.54 development branches still contained the truncated regex and duplicate trailing code, and are superseded by beta34.55.
- **Not a verified build/release.** Use the beta34.55 correction branch instead.

## v1.4.9-beta34.53 — Synthetic host labels and diagnostics
- Suppress `no_hoster_list` and other placeholder Hoster labels. For explicitly structured quality labels, use their hoster segment as a fallback.
- Add sanitized missing-method/stage diagnostics for extension Source settings; the AndroidX method mismatch still requires device diagnosis.
- **Previous reported APK compile failed** due to malformed provider source. No verified beta34.53 playback.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
