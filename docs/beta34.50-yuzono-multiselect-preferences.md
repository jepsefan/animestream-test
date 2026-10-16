# beta34.50 — Yūzōnō / Anikku multi-select preferences

Base: beta34.49. AnimeOnsen's external service appears degraded at time of development, so this beta focuses on other sources without touching AnimeOnsen.

- `ExtensionSourcePreferences` accepts source-defined `MultiSelectListPreference`, advertises option labels and current selected values, and validates all updates against declared options before persisting them as string sets.
- The Manage Providers [Beta] → Source settings dialog displays a multiple-choice checklist with Save and Cancel.
- AniWaves.ru declares Exclude Servers and Exclude Types this way; the bridge is generic, with no special case for AniWaves.
- All values remain stored per-source in Android SharedPreferences. Per-APK approvals and signing/version checks are unchanged.
- No changes to Better Player, subtitles, source search, or videos.

## Device test checklist

1. Build `1.4.9-beta34.50+61`; verify no Android Kotlin or Dart compile errors.
2. Enable AniWaves.ru [Ext] and open its Source settings. Look for Exclude Servers and Exclude Types.
3. Check some options, save, reopen and confirm the selections persist. Press Cancel on a new change and verify it does not save.
4. Test Animenosub [Ext] playback and its list-based settings, and verify a selected already-working extension is unaffected.
5. If AnimeOnsens servers recover, retest its HTTP 403 fallback separately.

**Status:** code committed; not independently built or device-verified.
Known deferred issue: some non-Latin subtitle characters (possibly Arabic) render as squares with crosses.
