package app.animestream

import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import dalvik.system.DexFile
import eu.kanade.tachiyomi.animesource.AnimeSource
import eu.kanade.tachiyomi.animesource.model.SAnime
import eu.kanade.tachiyomi.network.NetworkHelper
import java.io.File
import java.util.concurrent.TimeUnit
import kotlinx.serialization.json.Json
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.TypeReference

/**
 * One explicitly selected source result, no background discovery, episode streams
 * or playback. This does NOT guess an episode list from an AniList entry.
 */
internal class ExtensionEpisodeProbe(private val context: Context) {
    fun load(packageName: String, sourceUrl: String, sourceTitle: String): Map<String, Any?> {
        if (sourceUrl.isBlank() || sourceTitle.isBlank()) {
            return mapOf("status" to "invalid_selection")
        }
        return try {
            perform(packageName, sourceUrl, sourceTitle)
        } catch (error: Throwable) {
            val errors = mutableListOf<String>()
            val seen = java.util.Collections.newSetFromMap(
                java.util.IdentityHashMap<Throwable, Boolean>()
            )
            var throwable: Throwable? = error
            while (throwable != null && seen.add(throwable) && errors.size < 8) {
                errors.add(throwable.javaClass.simpleName + ": " + (throwable.message ?: ""))
                throwable = if (throwable is java.lang.reflect.InvocationTargetException) {
                    throwable.targetException ?: throwable.cause
                } else throwable.cause
            }
            mapOf(
                "status" to "episode_list_failed",
                "error" to errors.joinToString(" -> "),
                "stackTrace" to error.stackTraceToString().take(8000)
            )
        }
    }

    private fun perform(packageName: String, sourceUrl: String, sourceTitle: String): Map<String, Any?> {
        val app = context.applicationContext as? Application
            ?: return mapOf("status" to "missing_application")
        val helper = NetworkHelper.initialize(app)
        helper.beginSearchDiagnostics("")
        synchronized(ExtensionEpisodeProbe::class.java) {
            Injekt.addSingleton(object : TypeReference<Application> {
                override val type: java.lang.reflect.Type = Application::class.java
            }, app)
            Injekt.addSingleton(object : TypeReference<NetworkHelper> {
                override val type: java.lang.reflect.Type = NetworkHelper::class.java
            }, helper)
            Injekt.addSingleton(object : TypeReference<Json> {
                override val type: java.lang.reflect.Type = Json::class.java
            }, Json { ignoreUnknownKeys = true; explicitNulls = false })
        }
        val pm = context.packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getApplicationInfo(packageName,
                PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        }
        val sourceName = info.metaData?.getString("tachiyomi.animeextension.class")
            ?: return mapOf("status" to "no_source_class")
        val entry = sourceName.split(';', ',').first().trim().let {
            if (it.startsWith(".")) packageName + it else it
        }
        val paths = listOfNotNull(info.sourceDir) + (info.splitSourceDirs?.toList() ?: emptyList())
        val extensionClasses = paths.flatMap { apk ->
            val dex = DexFile(apk)
            try {
                val names = mutableListOf<String>()
                val enumeration = dex.entries()
                while (enumeration.hasMoreElements()) names.add(enumeration.nextElement())
                names
            } finally { dex.close() }
        }.toSet()
        val loader = ExtensionIsolatedClassLoader(
            paths.joinToString(File.pathSeparator),
            context.codeCacheDir.absolutePath,
            info.nativeLibraryDir, context.javaClass.classLoader, extensionClasses
        )
        val instance = Class.forName(entry, true, loader).getDeclaredConstructor().newInstance()
        val source = instance as? AnimeSource
            ?: return mapOf("status" to "not_anime_source")
        val anime = SAnime.create().apply {
            url = sourceUrl
            title = sourceTitle
        }
        val episodes = source.fetchEpisodeList(anime).toBlocking().toFuture()
            .get(25, TimeUnit.SECONDS)
        return mapOf(
            "status" to "episode_list_completed",
            "sourceTitle" to sourceTitle,
            "episodeCount" to episodes.size,
            "episodes" to episodes.take(100).map {
                mapOf(
                    "name" to it.name,
                    "url" to it.url,
                    "number" to it.episode_number,
                    "preview" to (it.preview_url ?: "")
                )
            },
            "truncated" to (episodes.size > 100),
            "networkDiagnostics" to helper.searchNetworkDiagnostics()
        )
    }
}
