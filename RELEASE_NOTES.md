# AnimeStream — Latest three beta development versions

Complete history: [CHANGELOG.md](CHANGELOG.md). These notes cover beta34.66, beta34.65 and beta34.64.

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

## v1.4.9-beta34.64 — Mobile Ext sub / built-in ASS providers
- Place **Ext sub** toggle in the actual mobile Episodes header; keep the desktop/TV toggle. Per-anime setting controls automatic external ASS lookup.
- Add AnimeOnsen, AniZone, Anikoto and Animegg as global Primary/Secondary source choices beside approved extensions. Support both legacy built-in subtitle URLs and extension subtitle tracks, with strict ASS verification and selected language filtering.
- Preserve working beta34.63 HLS external audio behavior, episode art and Discover behavior.
- Version `1.4.9-beta34.64+74`; no APK or device verification yet.

### Known limitations
- Some possibly Arabic subtitle characters display as squares with crosses. Logged and deferred by request; no font/rendering change.
- Some 123Anime hosts still return no playable video.
- Standalone external audio tracks cannot yet be selected for playback, and not every Anikku extension API is supported.
- Extension repository URLs remain user-supplied and local. APK installation requires signing checks and Android confirmation.

Older versions: [CHANGELOG.md](CHANGELOG.md).
