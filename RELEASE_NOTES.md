# v1.4.9 beta2–beta15 release notes

# AnimeStream v1.4.9 beta2–beta15 — development notes

These notes document the experimental branches. A feature being present in source code does not mean it was verified on a device. The user confirmed that ASS subtitles work in beta15.

## beta15 — Working ASS subtitles (user verified)
- Imported an updated `assrender-release.aar` from the beta15 branch of `jepsefan/assrender`.
- Restricted the AAR import workflow to successful builds from that branch.
- Native libass diagnostics now count active events and log the first active style when a frame is empty.
- **Confirmed by user:** ASS subtitles now display correctly in beta15.
- Aniyomi APK execution is **not** fixed by this release.

## beta14 — Android font selection and AAR import preparation
- Updated `jepsefan/assrender` native libass initialization to use an accessible Android system font (Roboto, with Noto Sans fallback) and `ASS_FONTPROVIDER_NONE`.
- Added native logs identifying the font provider and chosen default font path.
- Updated the AnimeStream import workflow for the beta14 branch.
- These changes were experimental; beta15 is the first build in this sequence reported to display ASS subtitles successfully.

## beta13 — ASS timing diagnostics
- Added parsing of ASS Dialogue cue start/end times in the Flutter external subtitle overlay.
- Logged parsed cue counts, first/last timestamps, and the number of active cues when the native renderer returned an empty frame.
- Logs showed active cues while the native renderer returned no image; the issue remained unresolved in beta13.

## beta12 — ASS bridge/AAR integration iteration
- Updated the bundled native AAR, Android method-channel registration and AAR import workflow.
- Native loading was observed in testing, but ASS frames could still be empty even with parsed events.

## beta11 — External libass overlay introduced
- Integrated the Android `assrender` AAR and native `ExternalAssRenderer` method channel.
- Added a Flutter external ASS/SSA overlay for playback and related watch-screen integration.
- Added integration documentation and an AAR import workflow.
- This is separate from Better Player's internal subtitle renderer.

## beta10 — Provider extension diagnostics
- Updated Android host-side extension integration and the Manage Providers screen.
- Aniyomi APK execution remained experimental, not a supported playable source.

## beta9 — Provider/extractor iterations
- Updated Android extension handling, Manage Providers, Vidtube extraction, Anikoto, and source selection code.
- These changes do not establish that external Aniyomi APKs can execute.

## beta8 — Source and extractor iteration
- Updated Vidtube extraction and source-tile handling.

## beta7 — Aniyomi extension bridge iteration
- Updated Android activity, the Aniyomi extension bridge, and Manage Providers.
- APK discovery/inspection should not be confused with successfully loading and executing extension classes.

## beta6 — Provider and subtitle parsing iteration
- Updated AnimeOnsen, ASS parsing, subtitle parser registration, and Manage Providers.

## beta5 — Versioned provider test
- Advanced the beta version. No additional source-code change is shown in the comparison against beta4.

## beta4 — Android provider test iteration
- Updated Android manifest configuration and the beta version.

## beta3 — Manage Providers experiment
- Added Installed/Available provider management, refresh, local Dart-source download/storage/removal and error reporting.
- External provider execution was disabled; downloaded sources were not playable.
- Provider preferences received null/lifecycle handling improvements.
- This beta was based directly on the master baseline rather than beta2.

## beta2 — AniDB player experiment
- Updated Better Player integration and the watch/player path.
- AniDB playback remained experimental; this version is not a verified AniDB playback fix.

## beta1 — AniDB V1/V2/V3 experiment
- Reintroduced three AniDB test variants and source registration.
- Tested request headers, HEAD checks, and bounded Range GET/media signature diagnostics.
- AniDB playback was not confirmed working.

## Outstanding
- Aniyomi APK extensions can be detected but may report `missing_host_api` and `ClassNotFoundException`; they are not yet confirmed executable or playable.
- Further ASS rendering behavior across different subtitle files, fonts, and Android TV devices has not been comprehensively verified.

---

# v1.4.9-beta3 — Manage Providers experiment

Based directly on the master baseline, not beta1/beta2. Adds a visible Manage Providers screen with Installed and Available tabs, refresh, local Dart source download/storage/removal, and error reporting. Fixes null handling and Hive box lifecycle in provider preferences. The upstream Provins catalog URL currently returns 404, so Available cannot populate until a valid compatible repository is configured. External provider execution remains disabled; downloaded code is not playable. No APK build or device test has been performed.

---

# v1.4.9-beta1 — AniDB playback experiment

Based on `v1.4.9` master. Reintroduces the AniDB V1/V2/V3 implementations and source registrations from the earlier beta30 test branch, without changing the Better Player fork or unrelated playback code. V1 uses Referer and HEAD diagnostics; V2 uses Referer, Origin and User-Agent; V3 adds a bounded HTTP Range GET probe to inspect media response status and MP4 signatures. This is a test release; AniDB playback remains unverified and may still fail.

---

# v1.4.9 Release Notes

This release is based on the `v1.4.8-beta23` application source, with version and documentation updates. It retains the subtitle/WebVTT, Android TV controls, SIMKL login/sync, AMOLED dimming, and experimental AniDB.se V1/V2/V3 features present in beta23. AniDB playback has not been confirmed working. Later beta24–beta30 code is intentionally excluded.

## v1.4.8 — Previous beta history

Earlier 1.4.8 beta builds covered WebVTT subtitle rendering and cue positioning, Android TV remote controls and decoder compatibility, SIMKL integration, AMOLED dimming, and experimental AniDB sources.

For the full beta1–beta23 notes and later experimental beta24–beta30 history, see [Detailed v1.4.8 release history](docs/RELEASE_NOTES_1.4.8_HISTORY.md).

