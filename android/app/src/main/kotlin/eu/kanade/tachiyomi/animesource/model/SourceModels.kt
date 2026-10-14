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
/**
 * Kotlin/JVM ABI for Aniyomi Video/Track/Hoster, including legacy constructors
 * used by older installed APK extensions. No playback is implemented here.
 */
data class Track(val url: String, val lang: String)

enum class ChapterType { Opening, Ending, Recap, MixedOp, Other }

data class TimeStamp(
    val start: Double,
    val end: Double,
    val name: String,
    val type: ChapterType = ChapterType.Other
)

data class Video(
    var videoUrl: String = "",
    val videoTitle: String = "",
    val resolution: Int? = null,
    val bitrate: Int? = null,
    val headers: okhttp3.Headers? = null,
    val preferred: Boolean = false,
    val subtitleTracks: List<Track> = emptyList(),
    val audioTracks: List<Track> = emptyList(),
    val timestamps: List<TimeStamp> = emptyList(),
    val mpvArgs: List<Pair<String, String>> = emptyList(),
    val ffmpegStreamArgs: List<Pair<String, String>> = emptyList(),
    val ffmpegVideoArgs: List<Pair<String, String>> = emptyList(),
    val internalData: String = "",
    val initialized: Boolean = false,
    val memo: kotlinx.serialization.json.JsonObject =
        kotlinx.serialization.json.JsonObject(emptyMap())
) {
    private var videoPageUrl: String = ""

    @Deprecated("Use videoTitle instead")
    val quality: String get() = videoTitle

    @Deprecated("Use videoUrl instead")
    val url: String get() = videoPageUrl

    // Original legacy constructor still used by 123Anime and AnimeOnsen.
    constructor(
        url: String,
        quality: String,
        videoUrl: String?,
        headers: okhttp3.Headers? = null,
        subtitleTracks: List<Track> = emptyList(),
        audioTracks: List<Track> = emptyList()
    ) : this(
        videoUrl = videoUrl ?: "null",
        videoTitle = quality,
        headers = headers,
        subtitleTracks = subtitleTracks,
        audioTracks = audioTracks
    ) {
        videoPageUrl = url
    }

    // Earlier extension libraries supported an Android Uri argument.
    @Suppress("UNUSED_PARAMETER")
    constructor(
        url: String,
        quality: String,
        videoUrl: String?,
        uri: android.net.Uri? = null,
        headers: okhttp3.Headers? = null
    ) : this(url, quality, videoUrl, headers)

    // Extensions compiled against the previous 14-field constructor.
    constructor(
        videoUrl: String,
        videoTitle: String,
        resolution: Int?,
        bitrate: Int?,
        headers: okhttp3.Headers?,
        preferred: Boolean,
        subtitleTracks: List<Track>,
        audioTracks: List<Track>,
        timestamps: List<TimeStamp>,
        mpvArgs: List<Pair<String, String>>,
        ffmpegStreamArgs: List<Pair<String, String>>,
        ffmpegVideoArgs: List<Pair<String, String>>,
        internalData: String,
        initialized: Boolean
    ) : this(
        videoUrl, videoTitle, resolution, bitrate, headers, preferred,
        subtitleTracks, audioTracks, timestamps, mpvArgs, ffmpegStreamArgs,
        ffmpegVideoArgs, internalData, initialized,
        kotlinx.serialization.json.JsonObject(emptyMap())
    )
}

open class Hoster(
    val hosterUrl: String = "",
    val hosterName: String = "",
    val videoList: List<Video>? = null,
    val internalData: String = "",
    val lazy: Boolean = false,
    val memo: kotlinx.serialization.json.JsonObject =
        kotlinx.serialization.json.JsonObject(emptyMap())
) {
    constructor(
        hosterUrl: String,
        hosterName: String,
        videoList: List<Video>?,
        internalData: String,
        lazy: Boolean
    ) : this(
        hosterUrl, hosterName, videoList, internalData, lazy,
        kotlinx.serialization.json.JsonObject(emptyMap())
    )
    companion object {
        const val NO_HOSTER_LIST = "no_hoster_list"
    }
}
