# AnimeStream v1.4.9-beta34.44 — Source preferences

Based on the user-verified beta34.43. The user reported AnimeOnsen streaming correctly and nine subtitle tracks present.

## Changes
- Adds a generic native `ExtensionSourcePreferences` bridge for `ConfigurableAnimeSource.setupPreferenceScreen` using an AndroidX PreferenceScreen.
- User-approved installed sources get a **Source settings** button in Settings → Manage Providers [Beta] → Installed.
- Supports source-declared `ListPreference` and `TwoStatePreference` controls, with bounded list sizes and source-defined entry values.
- Validates updates against the extension's defined options and change listeners rather than accepting arbitrary values.
- Preferences remain in per-source Android SharedPreferences (`source_<id>`). The repo catalog URL remains locally configured and never bundled.
- No changes to Better Player, subtitles, or source-specific video parsers.
- Build version: `1.4.9-beta34.44+55`.

## Testing and limitations
- **Not built or device verified**. In particular, test AndroidX `PreferenceManager`/screen creation and the extension's `setupPreferenceScreen` in a release APK before treating this as working.
- A source's settings code executes only after the user taps Source settings; only enabled `[Ext]` entries are shown.
- No free-text inputs, passwords, or arbitrary intent/action controls. Other preferences are intentionally omitted.
- Animenosub declares video quality, SUB/RAW type and preferred server lists; verify that they appear and persist after app restart and that video sorting follows the new preferences.
- Other extensions may have unsupported custom settings and can return an empty list.
- Existing issue deferred by user: some likely Arabic subtitles display replacement squares/crosses. Do not modify font/renderer as part of this beta.
- Regression tests: AnimeOnsen [Ext] playback, nine subtitles listed, and Animenosub [Ext] playback.
