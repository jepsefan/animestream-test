package eu.kanade.tachiyomi.animesource

import eu.kanade.tachiyomi.animesource.model.Hoster
import eu.kanade.tachiyomi.animesource.model.SAnime
import eu.kanade.tachiyomi.animesource.model.SEpisode
import eu.kanade.tachiyomi.animesource.model.Video
import rx.Observable

/**
 * Source-facing API modeled on Anikku's source-api AnimeSource contract.
 * Keep catalogue/search methods in AnimeCatalogueSource, not on this interface.
 *
 * The legacy RxJava implementations remain callable by modern suspend methods.
 * Full binary API compatibility must still be validated against target APKs.
 */
interface AnimeSource {
    val id: Long
    val name: String
    val lang: String get() = ""

    suspend fun getAnimeDetails(anime: SAnime): SAnime =
        fetchAnimeDetails(anime).toBlocking().single()

    suspend fun getEpisodeList(anime: SAnime): List<SEpisode> =
        fetchEpisodeList(anime).toBlocking().single()

    suspend fun getHosterList(episode: SEpisode): List<Hoster> =
        throw IllegalStateException("Not used")

    suspend fun getVideoList(hoster: Hoster): List<Video> =
        throw IllegalStateException("Not used")

    suspend fun getVideoList(episode: SEpisode): List<Video> =
        fetchVideoList(episode).toBlocking().single()

    @Deprecated("Use getAnimeDetails instead")
    fun fetchAnimeDetails(anime: SAnime): Observable<SAnime> =
        throw IllegalStateException("Not used")

    @Deprecated("Use getEpisodeList instead")
    fun fetchEpisodeList(anime: SAnime): Observable<List<SEpisode>> =
        throw IllegalStateException("Not used")

    @Deprecated("Use getVideoList instead")
    fun fetchVideoList(episode: SEpisode): Observable<List<Video>> =
        throw IllegalStateException("Not used")

    // Anikku-compatible related-anime callback signatures. Optional.
    suspend fun getRelatedAnimeList(
        anime: SAnime,
        exceptionHandler: (Throwable) -> Unit,
        pushResults: suspend (Pair<String, List<SAnime>>, Boolean) -> Unit
    ): Unit = throw UnsupportedOperationException()

    suspend fun getRelatedMangaList(
        manga: SAnime,
        exceptionHandler: (Throwable) -> Unit,
        pushResults: suspend (Pair<String, List<SAnime>>, Boolean) -> Unit
    ) = getRelatedAnimeList(manga, exceptionHandler, pushResults)
}
