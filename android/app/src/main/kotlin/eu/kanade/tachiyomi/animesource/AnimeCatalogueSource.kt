package eu.kanade.tachiyomi.animesource

import eu.kanade.tachiyomi.animesource.model.AnimeFilterList
import eu.kanade.tachiyomi.animesource.model.AnimesPage
import eu.kanade.tachiyomi.animesource.model.SAnime
import rx.Observable

/**
 * Search-specific ABI modeled on Anikku AnimeCatalogueSource.
 * Suspend defaults bridge legacy RxJava implementations.
 */
interface AnimeCatalogueSource : AnimeSource {
    override val lang: String
    val supportsLatest: Boolean

    suspend fun getPopularAnime(page: Int): AnimesPage =
        fetchPopularAnime(page).toBlocking().single()

    suspend fun getSearchAnime(page: Int, query: String, filters: AnimeFilterList): AnimesPage =
        fetchSearchAnime(page, query, filters).toBlocking().single()

    suspend fun getLatestUpdates(page: Int): AnimesPage =
        fetchLatestUpdates(page).toBlocking().single()

    fun getFilterList(): AnimeFilterList

    @Deprecated("Use getPopularAnime instead")
    fun fetchPopularAnime(page: Int): Observable<AnimesPage>

    @Deprecated("Use getSearchAnime instead")
    fun fetchSearchAnime(page: Int, query: String, filters: AnimeFilterList): Observable<AnimesPage>

    @Deprecated("Use getLatestUpdates instead")
    fun fetchLatestUpdates(page: Int): Observable<AnimesPage>

    // Optional Anikku source settings / related-item compatibility hooks.
    val supportsRelatedAnimes: Boolean get() = false
    val supportsRelatedMangas: Boolean get() = supportsRelatedAnimes
    val disableRelatedAnimesBySearch: Boolean get() = false
    val disableRelatedMangasBySearch: Boolean get() = disableRelatedAnimesBySearch
    val disableRelatedAnimes: Boolean get() = false
    val disableRelatedMangas: Boolean get() = disableRelatedAnimes

    suspend fun fetchRelatedAnimeList(anime: SAnime): List<SAnime> =
        throw UnsupportedOperationException()

    suspend fun fetchRelatedMangaList(manga: SAnime): List<SAnime> =
        fetchRelatedAnimeList(manga)
}
