# AnimeStream beta34.52 — Preserve Anikku hoster labels

**Base:** beta34.51; user confirmed previously failing extension sources could find episodes again.

## Changes
- `ExtensionSourceCalls.videos` now returns an internal video candidate that keeps the originating `hosterName` independent from the video's URL, quality and tracks.
- Modern Hoster implementations (including sources like AnimePahe) receive labels in the server chooser: `[Ext] source • hoster`. The label is capped at 80 characters and stripped of control characters; hoster URL and internal data are never passed to UI diagnostics.
- Legacy episode-only extensions have no separate hoster label and keep the previous user-visible server name.
- `resolveVideo(Video)` and legacy `getVideoUrl(Video)` still preserve video tracks, headers and the associated hoster name.
- Source setting list selections display extension-defined human-readable entries where available; stored values remain unchanged.
- No modifications to AnimeOnsen fallback, Better Player, ASS subtitle renderer, extension trust/approval, or the known deferred missing-glyph issue.

## Verification
**Not built or device tested.** Build `1.4.9-beta34.52+63` from the new branch. Test AnimePahe [Ext] with more than one Hoster and verify distinct server labels, then Animenosub [Ext] and AnimeOnsen [Ext] (when online) for unchanged streams and subtitle tracks. Check that source settings still save and reopen correctly.
