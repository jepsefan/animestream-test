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
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.Request
import org.jsoup.Jsoup

/** Explicit opt-in test only. Loads third-party extension code and may make network calls. */
internal class ExtensionSearchProbe(private val context: Context) {
    fun search(
        packageName: String, query: String, sourceId: Long? = null,
        approvedName: String? = null, approvedLanguage: String? = null
    ): Map<String, Any?> {
        if (query.isBlank()) return mapOf("status" to "invalid_query")
        return try {
            runSearch(packageName, query.trim(), sourceId, approvedName, approvedLanguage)
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
            val networkTrace = try {
                NetworkHelper.requireInstance().searchNetworkDiagnostics()
            } catch (_: IllegalStateException) { emptyList() }
            mapOf(
                "networkDiagnostics" to networkTrace,
                "status" to "search_failed",
                "okhttpRuntime" to (okhttpBody.classLoader?.javaClass?.name ?: "bootstrap"),
                "okhttpSourceSignatures" to sourceSignatures,
                "error" to (chain.joinToString(" -> ") +
                    "\nOkHttp ResponseBody source methods: " + sourceSignatures.joinToString("; ")),
                "errorChain" to chain,
                "stackTrace" to error.stackTraceToString().take(12000)
            )
        }
    }

    private fun runSearch(
        packageName: String, query: String, sourceId: Long?,
        approvedName: String?, approvedLanguage: String?
    ): Map<String, Any?> {
        val requiredRuntime = listOf(
            "uy.kohesive.injekt.InjektKt",
            "kotlinx.serialization.json.JsonObjectBuilder",
            "kotlinx.serialization.json.okio.OkioStreamsKt"
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
        networkHelper.beginSearchDiagnostics(query)
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
        val source = ExtensionHostRuntime(context).load(
            packageName, sourceId, approvedName, approvedLanguage
        ).source
        val entry = source.javaClass.name
        val catalogue = source as? eu.kanade.tachiyomi.animesource.AnimeCatalogueSource
            ?: return mapOf("status" to "not_catalogue_source", "className" to entry)
        val page = ExtensionSourceCalls.search(catalogue, query)
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
        // The source might use an alternate Japanese/romaji title. A direct
        // substring comparison can signal uncertainty, never prove an error.
        val normalizedQuery = normalizeTitle(query)
        val matches = results.count { result ->
            normalizeTitle(result["title"] as? String ?: "").contains(normalizedQuery)
        }
        val distinctTitles = results.map {
            normalizeTitle(it["title"] as? String ?: "")
        }.filter { it.isNotBlank() }.distinct().size
        val noDirectMatch = normalizedQuery.isNotBlank() && animes.isNotEmpty() && matches == 0
        val isAnimeOnsen = packageName ==
            "eu.kanade.tachiyomi.animeextension.all.animeonsen"
        val relevance = when {
            !noDirectMatch -> "direct_title_match_or_empty"
            // AnimeOnsen is confirmed to return romaji titles for English
            // searches. Do not report them as unrelated solely by string test.
            isAnimeOnsen -> "possible_alternate_titles"
            distinctTitles <= 2 && results.size >= 2 -> "possible_alternate_titles"
            else -> "unverified_unrelated_catalogue"
        }

        // Only compare endpoints when the legacy /filter endpoint was
        // actually called. Plain text 123Anime requests are routed to /search
        // by AnimeHttpSource, and an additional probe would be redundant.
        val networkPaths = networkHelper.searchNetworkDiagnostics()
            .mapNotNull { it["path"] as? String }
        val alternateProbe = if (noDirectMatch &&
            packageName == "eu.kanade.tachiyomi.animeextension.en.onetwothreeanime" &&
            "/filter" in networkPaths
        ) probe123AnimeAlternateSearch(query, networkHelper) else null

        return mapOf(
            "status" to if (noDirectMatch) "search_completed_unverified" else "search_completed",
            "query" to query, "sourceClass" to entry,
            "resultCount" to animes.size, "results" to results,
            "titleMatchCount" to matches,
            "resultRelevance" to relevance,
            "warning" to if (noDirectMatch && relevance == "possible_alternate_titles")
                "No literal title match. Results may use a Japanese/romaji alias; verify against AniList before treating them as unrelated."
                else if (noDirectMatch)
                "The source returned titles unrelated to the requested phrase. A default/browse listing is possible; do not auto-match these results."
                else null,
            "alternateEndpoint" to alternateProbe,
            "networkDiagnostics" to networkHelper.searchNetworkDiagnostics(),
            "hasNextPage" to (read(page, "getHasNextPage") ?: false)
        )
    }

    private fun normalizeTitle(value: String): String =
        value.trim().lowercase().replace(Regex("\\s+"), " ")

    /**
     * Diagnostic probe only: compare 123Anime's website /search endpoint
     * with the /filter endpoint used by its external APK. Restrict to a
     * known host; do not log URL query values, credentials or response HTML.
     */
    private fun probe123AnimeAlternateSearch(
        query: String,
        networkHelper: NetworkHelper
    ): Map<String, Any?> {
        val url = "https://123animehub.cc/search".toHttpUrl().newBuilder()
            .addQueryParameter("keyword", query)
            .build()
        val request = Request.Builder()
            .url(url)
            .header("User-Agent", networkHelper.defaultUserAgentProvider())
            .build()
        return try {
            val shortClient = networkHelper.client.newBuilder()
                .callTimeout(10, TimeUnit.SECONDS)
                .build()
            shortClient.newCall(request).execute().use { response ->
                val html = response.body?.string().orEmpty()
                val doc = Jsoup.parse(html, url.toString())
                val titles = doc.select("div.film-list div.item")
                    .mapNotNull { item ->
                        item.selectFirst("a.name")?.text()?.trim()?.takeIf { it.isNotBlank() }
                            ?: item.selectFirst("img[alt]")?.attr("alt")?.trim()
                                ?.takeIf { it.isNotBlank() }
                    }
                val normalizedQuery = normalizeTitle(query)
                mapOf(
                    "endpoint" to "/search",
                    "httpStatus" to response.code,
                    "resultCount" to titles.size,
                    "directTitleMatches" to titles.count {
                        normalizeTitle(it).contains(normalizedQuery)
                    },
                    "sampleTitles" to titles.take(5)
                )
            }
        } catch (error: Exception) {
            mapOf(
                "endpoint" to "/search",
                "error" to error.javaClass.simpleName + ": " +
                    (error.message ?: "unknown")
            )
        }
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
