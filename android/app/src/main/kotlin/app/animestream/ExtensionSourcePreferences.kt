package app.animestream

import android.content.Context
import androidx.preference.ListPreference
import androidx.preference.MultiSelectListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceGroup
import androidx.preference.PreferenceManager
import androidx.preference.TwoStatePreference
import eu.kanade.tachiyomi.animesource.ConfigurableAnimeSource

/**
 * Inspect and edit a small, explicit subset of an enabled extension source's
 * own preference screen. This does not fabricate source-specific settings.
 *
 * The Flutter UI obtains the source ID only from user-approved source records.
 * Invoking this runtime executes the installed extension's setupPreferenceScreen.
 * All values stay in AnimeStream's per-source Android SharedPreferences.
 */
internal class ExtensionSourcePreferences(private val context: Context) {
    private data class Setup(
        val source: ConfigurableAnimeSource,
        val screen: PreferenceGroup
    )

    private fun setup(packageName: String, sourceId: Long): Setup {
        val loaded = try {
            ExtensionHostRuntime(context).load(packageName, sourceId).source
        } catch (error: Throwable) {
            throw ExtensionDiscoveryStageFailure("settings_load_source", error)
        }
        val configurable = loaded as? ConfigurableAnimeSource
            ?: throw IllegalArgumentException("Source does not support settings")
        val screen = try {
            val manager = PreferenceManager(context)
            // Match ConfigurableAnimeSource.preferenceKey() from the shared host API.
            manager.sharedPreferencesName = "source_${loaded.id}"
            val prepared = manager.createPreferenceScreen(context)
            configurable.setupPreferenceScreen(prepared)
            prepared
        } catch (error: Throwable) {
            throw ExtensionDiscoveryStageFailure("settings_build_screen", error)
        }
        return Setup(configurable, screen)
    }

    private fun collect(group: PreferenceGroup, result: MutableList<Preference>) {
        for (index in 0 until group.preferenceCount) {
            val preference = group.getPreference(index)
            if (preference is PreferenceGroup) collect(preference, result)
            else result.add(preference)
        }
    }

    private fun safeKey(key: String?): Boolean =
        key != null && key.length in 1..96 &&
            key.matches(Regex("[A-Za-z0-9_.-]+")) &&
            listOf("password", "secret", "token", "cookie", "authorization",
                "apikey", "api_key").none { key.contains(it, ignoreCase = true) }

    private fun safePreferences(screen: PreferenceGroup): List<Preference> =
        mutableListOf<Preference>().also { collect(screen, it) }
            .filter { safeKey(it.key) && it.isEnabled &&
                (it is ListPreference || it is MultiSelectListPreference ||
                    it is TwoStatePreference) }
            .take(32)

    fun list(packageName: String, sourceId: Long): Map<String, Any?> {
        return try {
            val (source, screen) = setup(packageName, sourceId)
            val available = safePreferences(screen)
            val records = available.mapNotNull { preference ->
                val key = preference.key ?: return@mapNotNull null
                val title = preference.title?.toString()?.take(140)
                    ?.takeIf { it.isNotBlank() } ?: key
                when (preference) {
                    is ListPreference -> {
                        val values = preference.entryValues?.map { it.toString() }
                            ?: emptyList()
                        val entries = preference.entries?.map { it.toString() }
                            ?: emptyList()
                        if (values.isEmpty() || values.size != entries.size ||
                            values.size > 64 || values.any { it.length > 160 }) {
                            null
                        } else {
                            mapOf(
                                "key" to key,
                                "title" to title,
                                "type" to "list",
                                "value" to (preference.value ?: ""),
                                "entries" to entries.map { it.take(140) },
                                "values" to values
                            )
                        }
                    }
                    is MultiSelectListPreference -> {
                        val values = preference.entryValues?.map { it.toString() }
                            ?: emptyList()
                        val entries = preference.entries?.map { it.toString() }
                            ?: emptyList()
                        if (values.isEmpty() || values.size != entries.size ||
                            values.size > 64 || values.any { it.length > 160 }) {
                            null
                        } else {
                            val selected = preference.values ?: emptySet()
                            mapOf(
                                "key" to key,
                                "title" to title,
                                "type" to "multi_select",
                                "value" to values.filter { it in selected },
                                "entries" to entries.map { it.take(140) },
                                "values" to values
                            )
                        }
                    }
                    is TwoStatePreference -> mapOf(
                        "key" to key,
                        "title" to title,
                        "type" to "boolean",
                        "value" to preference.isChecked
                    )
                    else -> null
                }
            }
            mapOf(
                "status" to "ok",
                "sourceName" to source.name.take(140),
                "preferences" to records
            )
        } catch (e: IllegalArgumentException) {
            mapOf("status" to "unsupported")
        } catch (e: Throwable) {
            ExtensionLinkageDiagnostics.describeDiscovery(e)
        }
    }

    fun change(
        packageName: String, sourceId: Long, key: String, value: Any?
    ): Map<String, Any?> {
        if (!safeKey(key)) return mapOf("status" to "invalid_preference")
        return try {
            val (_, screen) = setup(packageName, sourceId)
            val preference = safePreferences(screen).firstOrNull { it.key == key }
                ?: return mapOf("status" to "invalid_preference")
            when (preference) {
                is ListPreference -> {
                    val selected = value as? String
                        ?: return mapOf("status" to "invalid_value")
                    if (preference.entryValues?.any { it.toString() == selected } != true)
                        return mapOf("status" to "invalid_value")
                    if (!preference.callChangeListener(selected))
                        return mapOf("status" to "change_rejected")
                    preference.value = selected
                }
                is MultiSelectListPreference -> {
                    val provided = value as? List<*>
                        ?: return mapOf("status" to "invalid_value")
                    if (provided.size > 64 || provided.any { it !is String }) {
                        return mapOf("status" to "invalid_value")
                    }
                    val selected = provided.filterIsInstance<String>().toSet()
                    val allowed = preference.entryValues?.map { it.toString() }?.toSet()
                        ?: return mapOf("status" to "invalid_preference")
                    if (!allowed.containsAll(selected)) {
                        return mapOf("status" to "invalid_value")
                    }
                    if (!preference.callChangeListener(selected)) {
                        return mapOf("status" to "change_rejected")
                    }
                    preference.values = selected
                }
                is TwoStatePreference -> {
                    val selected = value as? Boolean
                        ?: return mapOf("status" to "invalid_value")
                    if (!preference.callChangeListener(selected))
                        return mapOf("status" to "change_rejected")
                    preference.isChecked = selected
                }
                else -> return mapOf("status" to "invalid_preference")
            }
            mapOf("status" to "updated")
        } catch (e: IllegalArgumentException) {
            mapOf("status" to "unsupported")
        } catch (e: Throwable) {
            ExtensionLinkageDiagnostics.describeDiscovery(e)
        }
    }
}
