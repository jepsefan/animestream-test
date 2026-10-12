package eu.kanade.tachiyomi.animesource

import eu.kanade.tachiyomi.animesource.model.*
import rx.Observable

/**
 * Initial Aniyomi catalogue interface, matching the Rx entry-point
 * signatures used by extensions. Suspend defaults are deliberately not
 * bridged to Rx until the coroutine/Rx adapter is integrated.
 */
interface AnimeCatalogueSource : AnimeSource {
    override val lang: String
    fun fetchPopularAnime(page: Int): Observable<AnimesPage>
    fun fetchSearchAnime(page: Int, query: String, filters: AnimeFilterList): Observable<AnimesPage>
    fun fetchLatestUpdates(page: Int): Observable<AnimesPage>
}
