# Aniyomi extensions are loaded dynamically from installed APKs.
# R8 cannot discover these cross-APK references from static call graphs.
-keep class eu.kanade.tachiyomi.animesource.** { *; }
-keep interface eu.kanade.tachiyomi.animesource.** { *; }
-keep class eu.kanade.tachiyomi.network.** { *; }
-keep class uy.kohesive.injekt.** { *; }
-keep class rx.** { *; }
-keep class okhttp3.** { *; }
-keep class org.jsoup.** { *; }

# Aniyomi extension bytecode references Kotlin runtime classes dynamically.
# Preserve their original binary names and members in release APKs.
-keep class kotlin.** { *; }
-keep interface kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
