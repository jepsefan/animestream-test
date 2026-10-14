# v1.4.9-beta34.28 — Extension model ABI alignment

Base: beta34.27.

## Changes
- Reworked `SourceModels.kt` to follow Anikku's nested `AnimeFilter` hierarchy (Header, Separator, Select, Text, CheckBox, TriState, Group, Sort, AutoComplete).
- Matched commonly used `Video` and `Hoster` JVM constructor signatures to Anikku's source-api while retaining additional compatibility overloads.
- Added original-title metadata accessors to `SAnime`, and `chapter_number` alias to `SEpisode`.
- Added `ExtensionAbiProbe.inspect()` and Flutter MethodChannel `inspectHostAbi`: a reflection-only diagnostic for local host class signatures, **without executing extension APK code**.
- Raised pubspec to `1.4.9-beta34.28+40`.

## Cautions
- The ABI probe checks the presence of method and constructor descriptors, not complete runtime/behavior compatibility.
- This is not a full import of Anikku's source-api; networking, preferences, serialization, JVM Kotlin default method behavior and installed APK signing trust still need work.
- No Flutter/Gradle APK build was run in this environment; branch is **not build-verified**. In particular, a release APK must be checked against R8 minification and real installed extension calls.
- Third-party APK execution requires the existing explicit user approval. Do not enable automatic extension code loading at startup.

## Next
- Build and run `inspectHostAbi`, then test source discovery, search, episodes, Hoster video routing and subtitle track mapping with trusted APKs.
- Investigate complete source API and models under pinned upstream commit using an ABI comparison process before widening support.
