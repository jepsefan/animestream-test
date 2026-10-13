# AnimeStream — latest three beta releases

Only the three most recent beta versions are kept here. When a new beta is added, the oldest entry moves to [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta34.7 — Preserve Okio ABI for external extensions (unverified)
- User confirmed successful 123Anime `Naruto` search with 28 results in beta34.6; existing in-app sources also work.
- AnimeOnsen still fails because R8 renamed the `okio.BufferedSource` return type of `okhttp3.ResponseBody.source()` to `pb`.
- Keep `okio.**` class and interface names to preserve Java method descriptors referenced by external APKs.
- No episode loading or playback yet. Build and device verification required for AnimeOnsen.

## v1.4.9-beta34.6 — AnimeHttpSource URL ABI and OkHttp alignment (unverified)
- Add source model and episode setUrlWithoutDomain methods used by 123Anime.
- Align OkHttp dependency with Aniyomi 5.4.0 and include ResponseBody.source method diagnostics for AnimeOnsen.
- Requires build and device testing. Playback and automatic matching remain unsupported.

## v1.4.9-beta34.5 — Aniyomi Host API compatibility (unverified)
- Add Aniyomi JsoupExtensionsKt parsing helpers for 123Anime.
- Add minimal NetworkHelper, protected AnimeHttpSource.getNetwork() access, and Injekt registration for AnimeOnsen.
- These are compatibility shims, not the full Aniyomi networking stack. Cloudflare handling and full cookie support are not implemented.
- Build and phone search still need verification. AnimePahe remains deferred.

