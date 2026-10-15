package eu.kanade.tachiyomi.animesource.online

import eu.kanade.tachiyomi.animesource.model.AnimesPage
import eu.kanade.tachiyomi.animesource.model.Hoster
import eu.kanade.tachiyomi.animesource.model.SAnime
import eu.kanade.tachiyomi.animesource.model.SEpisode
import eu.kanade.tachiyomi.animesource.model.Video
import eu.kanade.tachiyomi.util.asJsoup
import okhttp3.Response
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element

/**
 * The common Jsoup-based Anikku source API.
 *
 * Keep this class in the HOST APK, not a particular extension. Old Yuzono
 * "ParsedAnimeHttpLegacySource" classes inherit this exact JVM superclass.
 * Selectors have safe throwing defaults to support multiple historical
 * extension ABI generations without requiring unrelated selectors.
 */
@Suppress("unused")
abstract class ParsedAnimeHttpSource : AnimeHttpSource() {
    override fun popularAnimeParse(response: Response): AnimesPage {
        val document = response.asJsoup()
        return AnimesPage(
            document.select(popularAnimeSelector()).map(::popularAnimeFromElement),
            popularAnimeNextPageSelector()?.let { document.selectFirst(it) != null } ?: false
        )
    }
    protected open fun popularAnimeSelector(): String = unsupported("popularAnimeSelector")
    protected open fun popularAnimeFromElement(element: Element): SAnime =
        unsupported("popularAnimeFromElement")
    protected open fun popularAnimeNextPageSelector(): String? = null

    override fun searchAnimeParse(response: Response): AnimesPage {
        val document = response.asJsoup()
        return AnimesPage(
            document.select(searchAnimeSelector()).map(::searchAnimeFromElement),
            searchAnimeNextPageSelector()?.let { document.selectFirst(it) != null } ?: false
        )
    }
    protected open fun searchAnimeSelector(): String = unsupported("searchAnimeSelector")
    protected open fun searchAnimeFromElement(element: Element): SAnime =
        unsupported("searchAnimeFromElement")
    protected open fun searchAnimeNextPageSelector(): String? = null

    override fun latestUpdatesParse(response: Response): AnimesPage {
        val document = response.asJsoup()
        return AnimesPage(
            document.select(latestUpdatesSelector()).map(::latestUpdatesFromElement),
            latestUpdatesNextPageSelector()?.let { document.selectFirst(it) != null } ?: false
        )
    }
    protected open fun latestUpdatesSelector(): String = unsupported("latestUpdatesSelector")
    protected open fun latestUpdatesFromElement(element: Element): SAnime =
        unsupported("latestUpdatesFromElement")
    protected open fun latestUpdatesNextPageSelector(): String? = null

    override fun animeDetailsParse(response: Response): SAnime =
        animeDetailsParse(response.asJsoup())
    protected open fun animeDetailsParse(document: Document): SAnime =
        unsupported("animeDetailsParse(Document)")

    override fun relatedAnimeListParse(response: Response): List<SAnime> =
        response.asJsoup().select(relatedAnimeListSelector()).map(::relatedAnimeFromElement)

    override fun relatedMangaListParse(response: Response): List<SAnime> =
        relatedAnimeListParse(response)

    protected open fun relatedAnimeListSelector(): String = popularAnimeSelector()
    protected open fun relatedMangaListSelector(): String = relatedAnimeListSelector()
    protected open fun relatedAnimeFromElement(element: Element): SAnime =
        popularAnimeFromElement(element)
    protected open fun relatedMangaFromElement(element: Element): SAnime =
        relatedAnimeFromElement(element)

    override fun episodeListParse(response: Response): List<SEpisode> =
        response.asJsoup().select(episodeListSelector()).map(::episodeFromElement)

    protected open fun episodeListSelector(): String = unsupported("episodeListSelector")
    protected open fun episodeFromElement(element: Element): SEpisode =
        unsupported("episodeFromElement")

    override fun hosterListParse(response: Response): List<Hoster> =
        response.asJsoup().select(hosterListSelector()).map(::hosterFromElement)

    protected open fun hosterListSelector(): String = unsupported("hosterListSelector")
    protected open fun hosterFromElement(element: Element): Hoster =
        unsupported("hosterFromElement")

    override fun videoListParse(response: Response): List<Video> =
        response.asJsoup().select(videoListSelector()).map(::videoFromElement)

    protected open fun videoListSelector(): String = unsupported("videoListSelector")
    protected open fun videoFromElement(element: Element): Video =
        unsupported("videoFromElement")

    override fun videoUrlParse(response: Response): String =
        videoUrlParse(response.asJsoup())
    protected open fun videoUrlParse(document: Document): String =
        unsupported("videoUrlParse(Document)")

    // Historical multisrc source templates also expose season parsing hooks.
    protected open fun seasonListSelector(): String = unsupported("seasonListSelector")
    protected open fun seasonFromElement(element: Element): SAnime =
        unsupported("seasonFromElement")
    protected open fun seasonListParse(response: Response): List<SAnime> =
        response.asJsoup().select(seasonListSelector()).map(::seasonFromElement)

    private fun unsupported(method: String): Nothing =
        throw UnsupportedOperationException("Source must implement $method")
}
