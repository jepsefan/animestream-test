package eu.kanade.tachiyomi.animesource.model

/** Initial ABI types needed by AnimeSource; not a complete source-api model. */
open class AnimeFilter<T>(val name: String, val state: T)
class AnimeFilterList(val list: List<AnimeFilter<*>> = emptyList()) : List<AnimeFilter<*>> by list {
    constructor(vararg filters: AnimeFilter<*>) : this(filters.toList())
}
interface SAnime
interface SEpisode
class AnimesPage(val animes: List<SAnime>, val hasNextPage: Boolean)
class AnimeRelation(val name: String, val animes: List<SAnime>)
class SAnimeEpisodeUpdate(val anime: SAnime, val episodes: List<SEpisode>)
class SAnimeSeasonUpdate(val anime: SAnime, val seasons: List<SAnime>)
open class Hoster
class Video
