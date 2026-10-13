# AnimeStream — latest three beta releases

Only the three most recent beta versions are kept here. When a new beta is added, the oldest entry moves to [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.9 — Extension search diagnostics (unverified)
- Added privacy-safe request diagnostics: HTTP status, request host/path, authorization header presence (not token values), Cloudflare mitigation header and exact keyword comparison for 123Anime.
- Detect results that don't contain the requested phrase among displayed titles; show a warning instead of treating unrelated catalog results as verified search matches.
- AnimeOnsen may require a search token from its home page; HTTP 403 is not automatically an application or authentication error. Diagnostic-only; no Cloudflare bypass added.
- Keep existing extension runtime, ordinary sources, and all player behavior unchanged. Build/device verification required.

## v1.4.9-beta34.8 — Aniyomi JSON-Okio runtime (unverified)
- Add kotlinx-serialization-json-okio 1.9.0 and align kotlinx-serialization-json to 1.9.0, matching Aniyomi's JSON serialization version.
- Probe OkioStreamsKt before calling extensions to identify missing runtime dependency.
- Beta 34.7 device test confirmed 123Anime returns 28 results for Naruto; AnimeOnsen advanced past the Okio ABI error but now needs the serialization Okio bridge.
- Build/device verification still required; no episode loading or playback support yet.

## v1.4.9-beta34.7 — Preserve Okio ABI for external extensions (unverified)
- User confirmed successful 123Anime `Naruto` search with 28 results in beta34.6; existing in-app sources also work.
- AnimeOnsen still fails because R8 renamed the `okio.BufferedSource` return type of `okhttp3.ResponseBody.source()` to `pb`.
- Keep `okio.**` class and interface names to preserve Java method descriptors referenced by external APKs.
- No episode loading or playback yet. Build and device verification required for AnimeOnsen.
