package eu.kanade.tachiyomi.animesource

import eu.kanade.tachiyomi.animesource.model.*
import rx.Observable

/**
 * Binary-facing Aniyomi source contract.
 * Mirrors the upstream source API method signatures. This is only the
 * interface layer; model implementations and AnimeHttpSource remain pending.
 */
interface AnimeSource {
    val id: Long
    val name: String
    val lang: String get() = ""
    val supportsLatest: Boolean
    fun getFilterList(): AnimeFilterList = AnimeFilterList()
    suspend fun getPopularAnime(page: Int): AnimesPage
    suspend fun getLatestUpdates(page: Int): AnimesPage
    suspend fun getSearchAnime(page: Int, query: String, filters: AnimeFilterList): AnimesPage
    suspend fun getAnimeEpisodeUpdate(anime: SAnime, episodes: List<SEpisode>, fetchDetails: Boolean, fetchEpisodes: Boolean): SAnimeEpisodeUpdate
    suspend fun getAnimeSeasonUpdate(anime: SAnime, seasons: List<SAnime>, fetchDetails: Boolean, fetchSeasons: Boolean): SAnimeSeasonUpdate
    val supportsRelatedAnime: Boolean get() = false
    suspend fun getRelatedAnimeList(anime: SAnime): List<AnimeRelation>
    suspend fun getHosterList(episode: SEpisode): List<Hoster> = error("Not used")
    suspend fun getVideoList(hoster: Hoster): List<Video> = error("Not used")
    suspend fun getSeasonList(anime: SAnime): List<SAnime> = throw UnsupportedOperationException()
    suspend fun getVideoList(episode: SEpisode): List<Video> = throw UnsupportedOperationException()
    fun fetchAnimeDetails(anime: SAnime): Observable<SAnime> = throw UnsupportedOperationException()
    suspend fun getAnimeDetails(anime: SAnime): SAnime = throw UnsupportedOperationException()
    suspend fun getEpisodeList(anime: SAnime): List<SEpisode> = throw UnsupportedOperationException()
    fun fetchEpisodeList(anime: SAnime): Observable<List<SEpisode>> = throw UnsupportedOperationException()
    fun fetchVideoList(episode: SEpisode): Observable<List<Video>> = throw UnsupportedOperationException()
}
