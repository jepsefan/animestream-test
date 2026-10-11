# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta25 — ASS clock stall recovery and Aniyomi host API diagnostics
- ASS monotonic playback clock no longer caps interpolation at 1000 ms when the player backend reports an unchanged position. This targets ASS animations freezing while video continues.
- Re-anchor the subtitle clock on play/pause, buffering transitions, seek and significant drift **only when a fresh position report arrives**. Track stalled and recovered player position reports in [ASSRENDER][CLOCK] and 5-second performance logs.
- Extension diagnostics explicitly flag direct Aniyomi/Tachiyomi host API interfaces absent from the extension DEX inventory (e.g. ConfigurableAnimeSource), and show them in Manage Providers. This does not make extensions executable or bundle the host API.
- Retains the premultiplied-alpha assrender AAR and beta24 DEX parsing fix. AAR import workflow targets beta25.
- APK build and Android TV behavior have not yet been verified.

## v1.4.9-beta24 — ASS playback clock and Aniyomi DEX fix
- Interpolated subtitle clock between coarse player notifications; DEX header validation corrected; explicit dependency inspection status.

## v1.4.9-beta23 — Extension and ASS performance diagnostics
- DEX superclass/interfaces inspection and Flutter/native ASS performance logs.
