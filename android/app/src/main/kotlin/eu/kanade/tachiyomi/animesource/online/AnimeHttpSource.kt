package eu.kanade.tachiyomi.animesource.online

import eu.kanade.tachiyomi.animesource.AnimeCatalogueSource
import eu.kanade.tachiyomi.network.NetworkHelper
import eu.kanade.tachiyomi.animesource.model.*
import okhttp3.Headers
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import rx.Observable
import java.security.MessageDigest
import java.net.URI
import java.net.URISyntaxException

/**
 * First working HTTP/Rx bridge for Aniyomi's legacy source hooks.
 *
 * Deliberately limited to the common request/parse entry points. Upstream
 * AnimeHttpSource has additional methods and dependency-injected network
 * helpers that still need ABI-compatible implementations.
 */
abstract class AnimeHttpSource : AnimeCatalogueSource {
    abstract val baseUrl: String
    open fun getHomeUrl(): String = baseUrl
    open val versionId: Int = 1
    override val id: Long by lazy { generateId(name, lang, versionId) }

    // Aniyomi extensions link against protected getNetwork(): NetworkHelper.
    protected val network: NetworkHelper by lazy { NetworkHelper.requireInstance() }
    open val client: OkHttpClient get() = network.client
    val headers: Headers by lazy { headersBuilder().build() }

    protected open fun headersBuilder(): Headers.Builder =
        Headers.Builder().add("User-Agent", network.defaultUserAgentProvider())

    protected fun generateId(name: String, lang: String, versionId: Int): Long {
        val bytes = MessageDigest.getInstance("MD5")
            .digest("${name.lowercase()}/$lang/$versionId".toByteArray())
        var id = 0L
        for (i in 0 until 8) id = (id shl 8) or (bytes[i].toLong() and 255)
        return id and Long.MAX_VALUE
    }


    /**
     * Aniyomi's member extension methods are compiled as public instance methods
     * on AnimeHttpSource with JVM descriptors (SAnime, String) and (SEpisode, String).
     * Installed extensions call these directly during search-result parsing.
     */
    fun SAnime.setUrlWithoutDomain(url: String) {
        this.url = getUrlWithoutDomain(url)
    }

    fun SEpisode.setUrlWithoutDomain(url: String) {
        this.url = getUrlWithoutDomain(url)
    }

    private fun getUrlWithoutDomain(original: String): String {
        return try {
            val uri = URI(original)
            var result = uri.path ?: return original
            uri.query?.let { result += "?$it" }
            uri.fragment?.let { result += "#$it" }
            result
        } catch (_: URISyntaxException) {
            original
        }
    }

    override fun toString(): String = "$name (${lang.uppercase()})"

    protected open fun popularAnimeRequest(page: Int): Request = throw UnsupportedOperationException()
    protected open fun popularAnimeParse(response: Response): AnimesPage = throw UnsupportedOperationException()
    protected open fun searchAnimeRequest(page: Int, query: String, filters: AnimeFilterList): Request =
        throw UnsupportedOperationException()
    protected open fun searchAnimeParse(response: Response): AnimesPage = throw UnsupportedOperationException()
    protected open fun latestUpdatesRequest(page: Int): Request = throw UnsupportedOperationException()
    protected open fun latestUpdatesParse(response: Response): AnimesPage = throw UnsupportedOperationException()

    private fun <T> fetch(request: Request, parse: (Response) -> T): Observable<T> =
        Observable.fromCallable {
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) throw java.io.IOException("HTTP ${response.code}")
                parse(response)
            }
        }

    override fun fetchPopularAnime(page: Int): Observable<AnimesPage> =
        fetch(popularAnimeRequest(page), ::popularAnimeParse)

    override fun fetchSearchAnime(page: Int, query: String, filters: AnimeFilterList): Observable<AnimesPage> {
        val request = searchAnimeRequest(page, query, filters)
        // Compatibility routing for the installed 123Anime extension. Its
        // searchAnimeRequest() uses /filter?keyword=, which the current site
        // returns as an unfiltered browse list. The website's /search?keyword=
        // produces the requested titles and uses the exact same card markup,
        // handled by the extension's existing searchAnimeParse().
        //
        // Only redirect a plain text search, NOT advanced filters, browsing,
        // or any other extension. No APK modification or global interceptor.
        val is123Anime = javaClass.name ==
            "eu.kanade.tachiyomi.animeextension.en.onetwothreeanime.OneThreeTwoAnime"
        val compatibleHost = request.url.host in setOf("123animehub.cc", "123anime.la")
        val plainSearch = request.method == "GET" &&
            request.url.encodedPath == "/filter" &&
            query.isNotBlank() &&
            request.url.queryParameter("keyword")?.trim() == query.trim() &&
            request.url.queryParameterNames.all {
                it == "keyword" || it == "sort" || it == "page"
            } &&
            (request.url.queryParameter("sort") == null ||
                request.url.queryParameter("sort") == "default")
        val effectiveRequest = if (is123Anime && compatibleHost && plainSearch) {
            request.newBuilder().url(
                request.url.newBuilder()
                    .encodedPath("/search")
                    .removeAllQueryParameters("sort")
                    .build()
            ).build()
        } else {
            request
        }
        return fetch(effectiveRequest, ::searchAnimeParse)
    }

    override fun fetchLatestUpdates(page: Int): Observable<AnimesPage> =
        fetch(latestUpdatesRequest(page), ::latestUpdatesParse)

    open fun animeDetailsRequest(anime: SAnime): Request =
        Request.Builder().url(baseUrl + anime.url).headers(headers).build()
    protected open fun animeDetailsParse(response: Response): SAnime =
        throw UnsupportedOperationException()
    open fun episodeListRequest(anime: SAnime): Request =
        Request.Builder().url(baseUrl + anime.url).headers(headers).build()
    protected open fun episodeListParse(response: Response): List<SEpisode> =
        throw UnsupportedOperationException()

    override fun fetchAnimeDetails(anime: SAnime): Observable<SAnime> =
        fetch(animeDetailsRequest(anime)) { animeDetailsParse(it).apply { initialized = true } }

    override fun fetchEpisodeList(anime: SAnime): Observable<List<SEpisode>> =
        fetch(episodeListRequest(anime), ::episodeListParse)

    // Compatibility hooks required by Anikku's ParsedAnimeHttpSource.
    protected open fun relatedAnimeListParse(response: Response): List<SAnime> =
        throw UnsupportedOperationException()
    protected open fun relatedMangaListParse(response: Response): List<SAnime> =
        relatedAnimeListParse(response)
    protected open fun hosterListParse(response: Response): List<Hoster> =
        throw UnsupportedOperationException()

    protected open fun videoUrlParse(response: Response): String =
        throw UnsupportedOperationException()

    // Anikku extensions-lib 1.6 Hoster request/parse API. These defaults
    // preserve older extensions that only implement per-episode video lists.
    protected open fun hosterListRequest(episode: SEpisode): Request =
        Request.Builder().url(baseUrl + episode.url).headers(headers).build()

    protected open fun videoListRequest(hoster: Hoster): Request =
        Request.Builder().url(hoster.hosterUrl).headers(headers).build()

    protected open fun videoListParse(response: Response, hoster: Hoster): List<Video> =
        throw UnsupportedOperationException("Hoster parser not implemented")

    override suspend fun getHosterList(episode: SEpisode): List<Hoster> =
        fetch(hosterListRequest(episode), ::hosterListParse)
            .toBlocking().single().let { hosters ->
                with(this) { hosters.sortHosters() }
            }

    override suspend fun getVideoList(hoster: Hoster): List<Video> =
        fetch(videoListRequest(hoster)) { videoListParse(it, hoster) }
            .toBlocking().single().let { videos ->
                with(this) { videos.sortVideos() }
            }

    // Historical lazy URL resolution hooks. Only explicitly requested by
    // the bridge for unresolved video placeholders, never valid media URLs.
    protected open fun videoUrlRequest(video: Video): Request =
        Request.Builder().url(video.videoPageUrl).headers(headers).build()

    open fun fetchVideoUrl(video: Video): Observable<String> =
        fetch(videoUrlRequest(video), ::videoUrlParse)

    open suspend fun getVideoUrl(video: Video): String =
        fetchVideoUrl(video).toBlocking().single()

    protected open fun List<Hoster>.sortHosters(): List<Hoster> = this
    protected open fun List<Video>.sortVideos(): List<Video> = this
    protected open fun List<Video>.sort(): List<Video> = this

    /**
     * Anikku extensions-lib 1.6 resolver hook. A hoster may provide videos
     * that are resolved lazily (e.g. the playable URL is obtained later).
     * The default is deliberately a no-op, matching upstream semantics and
     * preserving already-playable videos from legacy extensions.
     */
    open suspend fun resolveVideo(video: Video): Video? = video

    // Legacy Rx API used by the tested Aniyomi extension APKs.
    protected open fun videoListRequest(episode: SEpisode): Request =
        Request.Builder().url(baseUrl + episode.url).headers(headers).build()

    protected open fun videoListParse(response: Response): List<Video> =
        throw UnsupportedOperationException("Extension must implement videoListParse")

    override fun fetchVideoList(episode: SEpisode): Observable<List<Video>> =
        fetch(videoListRequest(episode), ::videoListParse)

}
