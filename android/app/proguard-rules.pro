# Aniyomi extensions are loaded dynamically from installed APKs.
# R8 cannot discover these cross-APK references from static call graphs.
-keep class eu.kanade.tachiyomi.animesource.** { *; }
-keep interface eu.kanade.tachiyomi.animesource.** { *; }
-keep class eu.kanade.tachiyomi.network.** { *; }
# Top-level JsoupExtensionsKt methods are called from external APKs via JVM linkage.
-keep class eu.kanade.tachiyomi.util.** { *; }
-keep class uy.kohesive.injekt.** { *; }
-keep class rx.** { *; }
-keep class okhttp3.** { *; }
# External Aniyomi APKs invoke okhttp3.ResponseBody.source(): okio.BufferedSource.
# Preserve the Okio binary type names in its JVM method descriptor. In beta34.6
# R8 renamed BufferedSource to "pb", causing NoSuchMethodError in AnimeOnsen.
-keep class okio.** { *; }
-keep interface okio.** { *; }
-keep class org.jsoup.** { *; }

# Aniyomi extension bytecode references Kotlin runtime classes dynamically.
# Preserve their original binary names and members in release APKs.
-keep class kotlin.** { *; }
-keep interface kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }

# Aniyomi extensions invoke Kotlin serialization through dynamically loaded bytecode.
-keep class kotlinx.serialization.** { *; }
-keep interface kotlinx.serialization.** { *; }
