# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.67, beta34.66 and beta34.65.

## v1.4.9-beta34.67 — Re:ANIME Hoster constructor ABI compatibility
- Resolve the exact beta34.66 failure: Re:ANIME requires Kotlin Hoster(String, String, List, String, boolean, int, DefaultConstructorMarker). Add the upstream-compatible five-field primary Hoster constructor with lazy support.
- Retain an older four-field constructor, including its Kotlin default-arguments mask overload, for already-compiled extensions. Preserve optional legacy six-field compatibility and both copy shapes.
- Keep HLS audio, external ASS and all earlier source/Discover changes.
- Version `1.4.9-beta34.67+77`. Flutter APK build and device playback not yet verified; any additional missing Host API method will need its own targeted correction.

## v1.4.9-beta34.66 — Re:ANIME missing JVM method diagnostics
- Re:ANIME in beta34.65 fails with `NoSuchMethodError` inside `getHosterList` while playing in Anikku on the same phone. The root method is not yet identified, so do not change working playback host classes speculatively.
- Report the **innermost** stream stage (e.g. `hoster_list`) instead of the generic `resolve_videos` wrapper.
- Extract only a validated Java method name, owning public class and JVM type descriptor from Android `NoSuchMethodError` into Stream test results. Never display arbitrary exception messages, full URLs, tokens, cookies or headers.
- Keep beta34.65 hoster routing diagnostics, beta34.64 mobile ASS toggle, and beta34.63 confirmed HLS audio.
- Version `1.4.9-beta34.66+76`; APK build and device check pending.

## v1.4.9-beta34.65 — Re:ANIME Hoster and DNS diagnostics
- For installed modern extensions declaring getHosterList, do not silently fall back to legacy episode getVideoList when the modern call fails; show the real hoster-list failure stage.
- Report the hostname of DNS lookup failures observed by the shared OkHttp client during an explicitly requested stream test. Do not expose full URLs, paths, headers, tokens or cookies.
- Distinguish hoster-list failures, hoster-video-list failures and legacy episode-video-list failures in Stream test results.
- Preserve beta34.64 mobile Ext sub, inbuilt subtitle providers and working beta34.63 separate HLS audio. README unchanged.
- Version `1.4.9-beta34.65+75`. Not yet APK built or tested on device; further Re:ANIME API and host compatibility work may be needed.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
