# Beta34.41 — Anikku ParsedAnimeHttpSource compatibility

Based on beta34.40 and preserves the working beta34.38 AnimeOnsen extension runtime.

Observed on installed Animenosub v14.31: source discovery fails at `resolve_entry_point` with a `NoClassDefFoundError` involving `eu.kanade.tachiyomi.animesource.online.ParsedAnimeHttpSource`.

Implemented:
- Added the missing `ParsedAnimeHttpSource` superclass in the host APK with Jsoup-based parsing for popular/search/latest results, details, episodes, hosters and videos.
- Added the related-item/hoster/video URL parsing and sorting extension points to `AnimeHttpSource`.
- Reused the previously implemented `eu.kanade.tachiyomi.util.JsoupExtensionsKt` utility.
- Kept all modifications in the shared API rather than modifying a single extension or player.
- Version `1.4.9-beta34.41+52`.

This is **not yet build-verified** and does not guarantee ABI parity with every multisrc extension. In particular, Yūzōnō's `keiyoushi.utils.ParsedAnimeHttpLegacySource` and its multisrc libraries may have further dependencies when actual constructors execute. The new shared superclass is a prerequisite, not proof of successful Animenosub discovery, search or playback.

Test after compiling: Manage Providers -> Animenosub -> Enable / refresh sources. If it fails, capture only the redacted stage and missing class. Recheck AnimeOnsen [Ext] search, episodes and streams for regressions.
