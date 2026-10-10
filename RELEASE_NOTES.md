# v1.4.9-beta2 — Android TV player recovery

Built on beta1. Failed initialization should no longer trap the Android TV Back action behind visible controls. Initialization errors now include stack traces when available, and repeated identical Better Player exception events are deduplicated in the app's player log (not suppressed in the playback engine). AniDB V1/V2/V3 HTTP diagnostics remain enabled. This is an untested fix: it does not guarantee every exit path, resolve the underlying source error, or fix the unrelated Hive box-close issue.

---

# v1.4.9-beta1 — AniDB playback experiment

Based on `v1.4.9` master. Reintroduces the AniDB V1/V2/V3 implementations and source registrations from the earlier beta30 test branch, without changing the Better Player fork or unrelated playback code. V1 uses Referer and HEAD diagnostics; V2 uses Referer, Origin and User-Agent; V3 adds a bounded HTTP Range GET probe to inspect media response status and MP4 signatures. This is a test release; AniDB playback remains unverified and may still fail.

---

# v1.4.9 Release Notes

This release is based on the `v1.4.8-beta23` application source, with version and documentation updates. It retains the subtitle/WebVTT, Android TV controls, SIMKL login/sync, AMOLED dimming, and experimental AniDB.se V1/V2/V3 features present in beta23. AniDB playback has not been confirmed working. Later beta24–beta30 code is intentionally excluded.

## Changes inherited from v1.4.8-beta23

- Stable Overlap and WebVTT subtitle handling, including cue positioning and formatting.
- Android TV remote playback controls and D-pad seeking.
- SIMKL login and synchronization improvements.
- AMOLED dimming and other player refinements.
- Experimental AniDB.se source discovery; playback remains unverified.

For the detailed history of v1.4.8 beta1–beta23, see [CHANGELOG.md](CHANGELOG.md). Later beta24–beta30 experiments were not included in the v1.4.9 stable baseline; the AniDB experiments in v1.4.9-beta1 and beta2 are documented above.
