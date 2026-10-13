package app.animestream

import android.content.Context
import android.app.Application
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.TypeReference
import kotlinx.serialization.json.Json
import eu.kanade.tachiyomi.network.NetworkHelper
import android.content.pm.PackageManager
import dalvik.system.DexFile
import android.os.Build
import java.io.File
import java.util.concurrent.TimeUnit

/** Explicit opt-in test only. Loads third-party extension code and may make network calls. */
internal class ExtensionSearchProbe(private val context: Context) {
    fun search(packageName: String, query: String): Map<String, Any?> {
        if (query.isBlank()) return mapOf("status" to "invalid_query")
        return try {
            runSearch(packageName, query.trim())
        } catch (error: Throwable) {
            val chain = mutableListOf<String>()
            val visited = java.util.Collections.newSetFromMap(
                java.util.IdentityHashMap<Throwable, Boolean>()
            )
            var current: Throwable? = error
            while (current != null && visited.add(current) && chain.size < 8) {
                chain.add(current.javaClass.name + ": " + (current.message ?: "(no message)"))
                current = if (current is java.lang.reflect.InvocationTargetException) {
                    current.targetException ?: current.cause
                } else {
                    current.cause
                }
            }
            val okhttpBody = okhttp3.ResponseBody::class.java
            val sourceSignatures = okhttpBody.methods
                .filter { it.name == "source" || it.name == "getSource" }
                .map { it.toGenericString() }
            mapOf(
                "status" to "search_failed",
                "okhttpRuntime" to (okhttpBody.protectionDomain?.codeSource?.location?.toString() ?: okhttpBody.classLoader?.javaClass?.name ?: "unknown"),
                "okhttpSourceSignatures" to sourceSignatures,
                "error" to chain.joinToString(" -> "),
                "errorChain" to chain,
                "stackTrace" to error.stackTraceToString().take(12000)
            )
        }
    }

    private fun runSearch(packageName: String, query: String): Map<String, Any?> {
        val requiredRuntime = listOf(
            "uy.kohesive.injekt.InjektKt",
            "kotlinx.serialization.json.JsonObjectBuilder"
        )
        val missingRuntime = requiredRuntime.filter { name ->
            try {
                Class.forName(name, false, context.classLoader)
                false
            } catch (_: ClassNotFoundException) {
                true
            } catch (_: LinkageError) {
                true
            }
        }
        if (missingRuntime.isNotEmpty()) {
            return mapOf(
                "status" to "missing_host_runtime",
                "error" to "Missing host runtime classes: " + missingRuntime.joinToString(", "),
                "missingRuntimeClasses" to missingRuntime,
                "query" to query
            )
        }
        // Aniyomi extensions request Application from the host's global Injekt registry.
        // Register the real app instance before loading/initializing extension classes.
        val application = context.applicationContext as? Application
            ?: return mapOf(
                "status" to "missing_application",
                "error" to "Android applicationContext is not an Application"
            )
        val networkHelper = NetworkHelper.initialize(application)
        synchronized(ExtensionSearchProbe::class.java) {
            Injekt.addSingleton(object : TypeReference<Application> {
                override val type: java.lang.reflect.Type = Application::class.java
            }, application)
            Injekt.addSingleton(object : TypeReference<NetworkHelper> {
                override val type: java.lang.reflect.Type = NetworkHelper::class.java
            }, networkHelper)
            // AnimeOnsen retrieves Json via the same global Injekt container.
            Injekt.addSingleton(object : TypeReference<Json> {
                override val type: java.lang.reflect.Type = Json::class.java
            }, Json {
                ignoreUnknownKeys = true
                explicitNulls = false
            })
        }
        val pm = context.packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getApplicationInfo(packageName,
                PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        }
        val declared = info.metaData?.getString("tachiyomi.animeextension.class")
            ?: return mapOf("status" to "no_source_class")
        val entry = declared.split(';', ',').first().trim().let {
            if (it.startsWith(".")) packageName + it else it
        }
        val paths = listOfNotNull(info.sourceDir) +
            (info.splitSourceDirs?.toList() ?: emptyList())
        val extensionClasses = paths.flatMap { apk ->
            val dex = DexFile(apk)
            try {
                val entries = dex.entries()
                val names = mutableListOf<String>()
                while (entries.hasMoreElements()) names.add(entries.nextElement())
                names
            } finally { dex.close() }
        }.toSet()
        val loader = ExtensionIsolatedClassLoader(
            paths.joinToString(File.pathSeparator),
            context.codeCacheDir.absolutePath, info.nativeLibraryDir,
            context.javaClass.classLoader,
            extensionClasses
        )
        val source = Class.forName(entry, true, loader).getDeclaredConstructor().newInstance()
        val catalogue = Class.forName(
            "eu.kanade.tachiyomi.animesource.AnimeCatalogueSource",
            false, context.javaClass.classLoader
        )
        if (!catalogue.isInstance(source)) {
            return mapOf("status" to "not_catalogue_source", "className" to entry)
        }
        val filtersClass = Class.forName(
            "eu.kanade.tachiyomi.animesource.model.AnimeFilterList",
            false, context.javaClass.classLoader
        )
        val filters = filtersClass.getDeclaredConstructor().newInstance()
        val method = catalogue.getMethod("fetchSearchAnime",
            Int::class.javaPrimitiveType, String::class.java, filtersClass)
        val observable = method.invoke(source, 1, query, filters) as rx.Observable<*>
        val page = observable.toBlocking().toFuture()
            .get(25, TimeUnit.SECONDS)
            ?: return mapOf("status" to "empty_response", "query" to query)
        val animes = read(page, "getAnimes", "getAnimeList") as? List<*>
            ?: return mapOf("status" to "unexpected_page_type",
                "pageClass" to page.javaClass.name)
        val results = animes.take(20).mapNotNull { anime ->
            if (anime == null) null else mapOf(
                "title" to (read(anime, "getTitle")?.toString() ?: ""),
                "url" to (read(anime, "getUrl")?.toString() ?: ""),
                "cover" to (read(anime, "getThumbnail_url",
                    "getThumbnailUrl")?.toString() ?: "")
            )
        }
        return mapOf("status" to "search_completed", "query" to query,
            "sourceClass" to entry, "resultCount" to animes.size,
            "results" to results,
            "hasNextPage" to (read(page, "getHasNextPage") ?: false))
    }

    private fun read(value: Any, vararg names: String): Any? {
        for (name in names) {
            val method = value.javaClass.methods.firstOrNull {
                it.name == name && it.parameterTypes.isEmpty()
            } ?: continue
            return method.invoke(value)
        }
        return null
    }
}
