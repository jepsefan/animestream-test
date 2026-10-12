package eu.kanade.tachiyomi.animesource

import android.content.SharedPreferences
import androidx.preference.PreferenceScreen

/**
 * Source preferences are deliberately not wired to the original Aniyomi DI
 * container. Until a per-source preferences host is installed, callers get
 * an explicit unsupported-operation error instead of silently sharing data.
 */
interface ConfigurableAnimeSource : AnimeSource {
    fun getSourcePreferences(): SharedPreferences =
        throw UnsupportedOperationException("Aniyomi source preferences host not initialized")
    fun setupPreferenceScreen(screen: PreferenceScreen)
}

fun ConfigurableAnimeSource.preferenceKey(): String = "source_$id"
