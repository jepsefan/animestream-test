# beta34.53 — Hoster display and preference linkage diagnostics

Based on beta34.52. User testing showed **Animenosub [Ext] • no_hoster_list** instead of VidMoly, even though quality contained `SUB - Omega - VidMoly - 720p`. Also, Source settings for AniWaves.ru failed at `settings_build_screen` with `NoSuchMethodError`.

- Do not present the synthetic hoster placeholder as a real server.
- Derive a display-only host name from the penultimate segment of an explicit four-part quality label ending in resolution. Keep raw quality text, stream URLs, headers and tracks unmodified.
- Retain real hoster names for modern source API users.
- Improve safe linkage diagnostics to show host call names and a sanitized missing-method name (when discoverable); **does not assert the AndroidX API incompatibility is fixed**.
- No change to player, subtitle rendering or the AnimeOnsen fallback.

Version `1.4.9-beta34.53+64`. Not built or device tested. Test Animenosub for VidMoly/other server labels, AnimePahe for its real hoster names, and retry AniWaves.ru Source settings. Report the sanitized method/stage if still failing.
