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

