# AnimeStream v1.4.9 — latest beta release notes

Only the current beta and the two previous betas are shown here. Earlier development notes are preserved in [CHANGELOG.md](CHANGELOG.md).

## v1.4.9-beta18 — ASS texture and extension diagnostics (experimental)
- Native ASS overlay uses Android SurfaceTexture and Flutter Texture instead of per-frame PNG transfer.
- Align the 1280×720 subtitle texture to a centered 16:9 viewport rather than stretching it across pillarbox bars (candidate fix for left-shifted ASS signs; requires device verification).
- Continue experimental Aniyomi extension APK/DEX/class-loading diagnostics already on the beta18 branch.
- **Known issue:** ASS transparency/alpha blending and sign positioning still require validation against beta16 screenshots. Extension APKs are detected but are not yet confirmed executable/playable.
- Better Player fork unchanged.

## v1.4.9-beta17 — Aniyomi class-loading diagnostics
- Expanded extension class and APK inspection, reporting DEX classes, candidates, class-loading errors, and root causes.
- AnimeOnsen extension still reported ClassNotFoundException and missing AnimeSource host API in device testing.
- ASS sign placement/transparency appeared worse than beta16 in user screenshots.

## v1.4.9-beta16 — ASS visual reference
- Reference build for more accurate ASS sign placement and partial transparency, as compared by the user.
- Used as the visual baseline for correcting beta17/18 regressions.

## Testing status
This beta18 branch has not been verified with a fresh Android TV APK after the viewport adjustment. A native libass alpha-compositing fix is still pending.
