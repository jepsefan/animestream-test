package eu.kanade.tachiyomi.animesource.model

/** Initial ABI types needed by AnimeSource; not a complete source-api model. */
open class AnimeFilter<T>(val name: String, val state: T)
class AnimeFilterList(val list: List<AnimeFilter<*>> = emptyList()) : List<AnimeFilter<*>> by list {
    constructor(vararg filters: AnimeFilter<*>) : this(filters.toList())
}
interface SAnime : java.io.Serializable {
    var url: String
    var title: String
    var thumbnail_url: String?
    var background_url: String?
    var artist: String?
    var author: String?
    var status: Int
    var description: String?
    var genre: String?
    var update_strategy: AnimeUpdateStrategy
    var fetch_type: FetchType
    var season_number: Double
    var initialized: Boolean
    var memo: kotlinx.serialization.json.JsonObject
    fun getGenres(): List<String>? = genre?.split(", ")?.map { it.trim() }?.filter { it.isNotBlank() }?.distinct()
    fun copy(): SAnime = create().also {
        it.url = url; it.title = title; it.thumbnail_url = thumbnail_url
        it.background_url = background_url; it.artist = artist; it.author = author
        it.status = status; it.description = description; it.genre = genre
        it.update_strategy = update_strategy; it.fetch_type = fetch_type
        it.season_number = season_number; it.initialized = initialized; it.memo = memo
    }
    companion object {
        const val UNKNOWN = 0
        const val ONGOING = 1
        const val COMPLETED = 2
        const val LICENSED = 3
        const val PUBLISHING_FINISHED = 4
        const val CANCELLED = 5
        const val ON_HIATUS = 6
        const val UPCOMING = 7
        fun create(): SAnime = SAnimeImpl()
    }
}
interface SEpisode : java.io.Serializable {
    var url: String
    var name: String
    var episode_number: Float
    var fillermark: Boolean
    var scanlator: String?
    var date_upload: Long
    var summary: String?
    var preview_url: String?
    var memo: kotlinx.serialization.json.JsonObject
    fun copyFrom(other: SEpisode) {
        name = other.name; url = other.url; date_upload = other.date_upload
        episode_number = other.episode_number; fillermark = other.fillermark
        scanlator = other.scanlator; summary = other.summary
        preview_url = other.preview_url; memo = other.memo
    }
    companion object { fun create(): SEpisode = SEpisodeImpl() }
}
enum class AnimeUpdateStrategy { ALWAYS_UPDATE, ONLY_FETCH_ONCE }
enum class FetchType { Seasons, Episodes }
class SAnimeImpl : SAnime {
    override lateinit var url: String
    override lateinit var title: String
    override var thumbnail_url: String? = null
    override var background_url: String? = null
    override var artist: String? = null
    override var author: String? = null
    override var status: Int = 0
    override var description: String? = null
    override var genre: String? = null
    override var update_strategy = AnimeUpdateStrategy.ALWAYS_UPDATE
    override var fetch_type = FetchType.Episodes
    override var season_number: Double = -1.0
    override var initialized: Boolean = false
    override var memo: kotlinx.serialization.json.JsonObject = kotlinx.serialization.json.JsonObject(emptyMap())
}
class SEpisodeImpl : SEpisode {
    override lateinit var url: String
    override lateinit var name: String
    override var episode_number: Float = -1f
    override var fillermark: Boolean = false
    override var scanlator: String? = null
    override var date_upload: Long = 0L
    override var summary: String? = null
    override var preview_url: String? = null
    override var memo: kotlinx.serialization.json.JsonObject = kotlinx.serialization.json.JsonObject(emptyMap())
}
class AnimesPage(val animes: List<SAnime>, val hasNextPage: Boolean)
class AnimeRelation(val name: String, val animes: List<SAnime>)
class SAnimeEpisodeUpdate(val anime: SAnime, val episodes: List<SEpisode>)
class SAnimeSeasonUpdate(val anime: SAnime, val seasons: List<SAnime>)
open class Hoster
class Video
