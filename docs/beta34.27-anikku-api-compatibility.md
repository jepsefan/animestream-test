# v1.4.9-beta34.27 — Anikku source interface alignment

Base branch: beta34.26 multi-source extension routing.

Changes:
- Align `AnimeSource.kt` with Anikku's method grouping: anime details, episode listing, direct video fetching and optional Hoster APIs.
- Move popular/latest/search/filter APIs to `AnimeCatalogueSource.kt` where they belong, including `supportsLatest`.
- Implement coroutine default methods for the common legacy RxJava operations using blocking terminal observables in the first prototype. The outer host adapter still enforces timeouts for its calls.
- Introduce related-item method signatures and optional catalogue property stubs for future extension compatibility.
- Keep source-specific player and subtitle code unchanged; preserve multi-source selection introduced in beta34.26.

## Important
This is **incremental API alignment**, not a claim of full Anikku runtime parity:
- The original Anikku source-api binary still has many other types and methods, and AnimeStream's older host models differ; Kotlin interface default-method JVM bytecode and library versions can also affect compatibility.
- No automated Flutter/Gradle build or device playback test was performed here. The branch is a compatibility prototype.
- Third-party APK execution still requires explicit user opt-in; APK-signature trust enforcement and installation are not yet implemented.
- Some older extensions may require ABI compatibility shims or their exact original host dependencies.
- Retain stable beta34.26 for comparison if regressions occur. Never treat one working source as proof that every extension works.

Suggested test sequence: compile Android release; install only a trusted compatible extension APK; verify discovery and source id, search, episodes, hosters/direct video, headers and language/ASS/VTT/SRT tracks. Compare failures with Anikku source API at pinned commit instead of adding per-site patches.
