# beta34.45 — AnimeOnsen [Ext] search HTTP 403 fallback

Observed on beta34.44: user screenshot shows POST `search.animeonsen.xyz/indexes/content/search` returned HTTP 403, `auth: other_present`, zero results; user reports built-in AnimeOnsen works.

Source analysis: the installed Yūzōnō extension's SearchInterceptor obtains `ao-search-token` from the website and inserts `Authorization: Bearer <token>`. This is separate from the built-in AnimeOnsen OAuth `api.animeonsen.xyz/v4/search` endpoint. A missing website token is plausible but has not been verified. HTTP 403 does not imply missing Host API classes.

## Change
- Only when the extension's search diagnostic confirms **exactly** HTTP 403 on `search.animeonsen.xyz/indexes/content/search`, try `AnimeOnsen.checkAndUpdateToken()` and the existing built-in `AnimeOnsen.search(query)`.
- Map search result `content_id` to the Anikku extension's anime URL identifier, preserving normal Aniyomi episode and stream handling after selection.
- Label fallback results and include a non-secret warning in the Manage Providers search diagnostic.
- Preserve extension failure on fallback error; do not log OAuth secrets, cookies, or URL query parameters.
- Other extensions and all successful AnimeOnsen [Ext] searches are untouched.
- Keep the last confirmed beta34.43 playback behavior; no changes to decoding, subtitle font fallback, or extension preferences.
- Version `1.4.9-beta34.45+56`.

## Validation
**User-reported device result:** After upgrading to beta34.45, the user confirmed the previously failing AnimeOnsen [Ext] operation now works. The report follows the 403 search error and fallback change; separate verification of every episode, playback and subtitle track was not supplied. No independent build run was performed here.

Test AnimeOnsen [Ext] search for a known series: the fallback should show `Search fallback: built-in AnimeOnsen API` only when the extension search returns the exact 403 above; then open a result, load episodes and verify playback/subtitles through [Ext]. Test built-in AnimeOnsen independently and Animenosub for regressions.

Previously documented issue remains deferred by request: some possibly Arabic subtitles show missing-glyph squares/crosses.
