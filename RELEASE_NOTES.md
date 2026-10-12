# AnimeStream v1.4.9 — latest beta release notes

Only the latest beta and two previous betas are shown here. Earlier history is in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta27 — ASS frequency and Aniyomi extension runtime (in progress)
- Implemented: Player Settings → Subtitle settings → ASS Renderer frequency (Auto, 30, 60, 120 FPS), persisted in Hive; vsync remains the upper bound and the existing serialized render path is preserved.
- Implemented: non-executing Aniyomi host API class availability probe, including transitive hierarchy dependencies and missing-host-class counts. Actual Aniyomi host API compatibility/runtime execution is not implemented yet.
- Status: development branch; no Android build or device test has been performed. Extension execution remains unsupported.

## v1.4.9-beta26 — ASS playback clock continuity
- Remove the remaining 1000 ms ASS interpolation cap so animations can advance while the Android TV player reports a stale position.
- Distinguish fresh and repeated player positions; only use fresh reports to correct clock drift, while pause/buffering and seek transitions still re-anchor.
- Add freshReports/staleReports counters to ASS performance logs for beta26 validation.
- Add metadata-only Aniyomi extension superclass/interface hierarchy diagnostics, including obfuscated superclass `i`, transitive missing dependencies and hierarchy scan errors. No extension code is executed and host API support is not yet implemented.
- Keep native assrender AAR and Better Player fork unchanged.
- APK build and Android TV behavior have not yet been verified.

## v1.4.9-beta25 — ASS clock stall recovery and Aniyomi host API diagnostics
- ASS monotonic playback clock no longer caps interpolation at 1000 ms when the player backend reports an unchanged position. This targets ASS animations freezing while video continues.
- Re-anchor the subtitle clock on play/pause, buffering transitions, seek and significant drift **only when a fresh position report arrives**. Track stalled and recovered player position reports in [ASSRENDER][CLOCK] and 5-second performance logs.
- Extension diagnostics explicitly flag direct Aniyomi/Tachiyomi host API interfaces absent from the extension DEX inventory (e.g. ConfigurableAnimeSource), and show them in Manage Providers. This does not make extensions executable or bundle the host API.
- Retains the premultiplied-alpha assrender AAR and beta24 DEX parsing fix. AAR import workflow targets beta25.
- APK build and Android TV behavior have not yet been verified.

## v1.4.9-beta24 — ASS playback clock and Aniyomi DEX fix
- Interpolated subtitle clock between coarse player notifications; DEX header validation corrected; explicit dependency inspection status.
