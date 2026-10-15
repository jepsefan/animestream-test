package app.animestream

import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import dalvik.system.DexFile
import eu.kanade.tachiyomi.animesource.AnimeSource
import eu.kanade.tachiyomi.animesource.AnimeSourceFactory
import eu.kanade.tachiyomi.animesource.AnimeCatalogueSource
import eu.kanade.tachiyomi.network.NetworkHelper
import java.io.File
import kotlinx.serialization.json.Json
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.TypeReference

/**
 * One shared, source-independent entry point for installed extension APKs.
 * Only call after explicit user action: constructing a source runs third-party code.
 */
internal class ExtensionHostRuntime(private val context: Context) {
    data class Loaded(val source: AnimeSource, val sourceCount: Int)
    private data class Cached(val versionCode: Long, val updatedAt: Long,
        val paths: List<String>, val sources: List<AnimeSource>)
    companion object {
        private val cache = mutableMapOf<String, Cached>()
        fun invalidate(packageName: String) {
            synchronized(cache) { cache.remove(packageName) }
        }
    }
    data class SourceInfo(
        val id: Long,
        val name: String,
        val language: String,
        val supportsLatest: Boolean
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "id" to id, "name" to name, "language" to language,
            "supportsLatest" to supportsLatest
        )
    }

    /** Explicit user-triggered discovery. Loading a source executes extension code. */
    fun discover(packageName: String): List<SourceInfo> =
        loadAll(packageName).map { source ->
            SourceInfo(
                source.id,
                source.name,
                source.lang,
                (source as? AnimeCatalogueSource)?.supportsLatest ?: false
            )
        }

    fun load(packageName: String, sourceId: Long? = null): Loaded {
        val sources = loadAll(packageName)
        val selected = if (sourceId == null) sources.first() else
            sources.firstOrNull { it.id == sourceId }
                ?: error("Selected source ID is not available in extension")
        return Loaded(selected, sources.size)
    }

    private fun loadAll(packageName: String): List<AnimeSource> =
        synchronized(cache) { loadAllLocked(packageName) }

    private fun loadAllLocked(packageName: String): List<AnimeSource> {
        val app = context.applicationContext as? Application
            ?: error("Android application is unavailable")
        val helper = NetworkHelper.initialize(app)
        synchronized(ExtensionHostRuntime::class.java) {
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
        val manager = context.packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            manager.getApplicationInfo(
                packageName, PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong())
            )
        } else {
            @Suppress("DEPRECATION")
            manager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        }
        // Anikku primarily declares a class list; support packages that
        // explicitly declare their source factory separately as well.
        val classEntries = info.metaData?.getString("tachiyomi.animeextension.class")
            .orEmpty().split(';', ',').map { it.trim() }.filter { it.isNotBlank() }
        val factoryEntry = info.metaData?.getString("tachiyomi.animeextension.factory")
            ?.trim()?.takeIf { it.isNotBlank() }
        val pkgInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            manager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            manager.getPackageInfo(packageName, 0)
        }
        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
            pkgInfo.longVersionCode else {
                @Suppress("DEPRECATION")
                pkgInfo.versionCode.toLong()
            }
        val paths = listOfNotNull(info.sourceDir) +
            (info.splitSourceDirs?.toList() ?: emptyList())
        cache[packageName]?.let { cached ->
            if (cached.versionCode == code && cached.updatedAt == pkgInfo.lastUpdateTime &&
                cached.paths == paths) return cached.sources
        }
        cache.remove(packageName)
        val entryPoints = (classEntries + listOfNotNull(factoryEntry)).distinct()
        require(entryPoints.isNotEmpty()) { "Extension has no source entry points" }
        val apkPaths = paths
        require(apkPaths.isNotEmpty()) { "No APK paths for extension" }
        val extensionClasses = mutableSetOf<String>()
        for (apk in apkPaths) {
            val dex = DexFile(apk)
            try {
                val entries = dex.entries()
                while (entries.hasMoreElements()) extensionClasses.add(entries.nextElement())
            } finally {
                dex.close()
            }
        }
        val loader = ExtensionIsolatedClassLoader(
            apkPaths.joinToString(File.pathSeparator),
            context.codeCacheDir.absolutePath,
            info.nativeLibraryDir,
            context.javaClass.classLoader,
            extensionClasses
        )
        val sources = entryPoints.flatMap { entry ->
            val name = if (entry.startsWith(".")) packageName + entry else entry
            val instance = Class.forName(name, true, loader)
                .getDeclaredConstructor().newInstance()
            when (instance) {
                is AnimeSourceFactory -> instance.createSources()
                is AnimeSource -> listOf(instance)
                else -> error("Extension entry point does not implement AnimeSource/AnimeSourceFactory: $name")
            }
        }.distinctBy { it.id }
        require(sources.isNotEmpty()) { "Extension created no anime sources" }
        cache[packageName] = Cached(code, pkgInfo.lastUpdateTime, paths, sources)
        return sources
    }
}
