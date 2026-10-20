package eu.kanade.tachiyomi.animesource.model

/**
 * Filter hierarchy compatible with the nested types used by Anikku extensions.
 * Keep the source API in a shared host classloader rather than packaged per APK.
 */
sealed class AnimeFilter<T>(val name: String, var state: T) {
    open class Header(name: String) : AnimeFilter<Any>(name, 0)
    open class Separator(name: String = "") : AnimeFilter<Any>(name, 0)
    abstract class Select<V>(name: String, val values: Array<V>, state: Int = 0) :
        AnimeFilter<Int>(name, state)
    abstract class Text(name: String, state: String = "") : AnimeFilter<String>(name, state)
    abstract class CheckBox(name: String, state: Boolean = false) :
        AnimeFilter<Boolean>(name, state)
    abstract class TriState(name: String, state: Int = STATE_IGNORE) :
        AnimeFilter<Int>(name, state) {
        fun isIgnored() = state == STATE_IGNORE
        fun isIncluded() = state == STATE_INCLUDE
        fun isExcluded() = state == STATE_EXCLUDE
        companion object {
            const val STATE_IGNORE = 0
            const val STATE_INCLUDE = 1
            const val STATE_EXCLUDE = 2
        }
    }
    abstract class Group<V>(name: String, state: List<V>) : AnimeFilter<List<V>>(name, state)
    abstract class Sort(name: String, val values: Array<String>, state: Selection? = null) :
        AnimeFilter<Sort.Selection?>(name, state) {
        data class Selection(val index: Int, val ascending: Boolean)
    }
    abstract class AutoComplete(
        name: String,
        val hint: String,
        val values: List<String>,
        val skipAutoFillTags: List<String> = emptyList(),
        val validPrefixes: List<String> = emptyList(),
        state: List<String>
    ) : AnimeFilter<List<String>>(name, state)

    override fun equals(other: Any?): Boolean =
        this === other || (other is AnimeFilter<*> && name == other.name && state == other.state)

    override fun hashCode(): Int = 31 * name.hashCode() + (state?.hashCode() ?: 0)
}
class AnimeFilterList(val list: List<AnimeFilter<*>> = emptyList()) : List<AnimeFilter<*>> by list {
    constructor(vararg fs: AnimeFilter<*>) : this(fs.toList())
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

    // Public Anikku ABI getters used by source parsing and related titles.
    val originalTitle: String get() = title
    val originalAuthor: String? get() = author
    val originalArtist: String? get() = artist
    val originalThumbnailUrl: String? get() = thumbnail_url
    val originalDescription: String? get() = description
    val originalGenre: String? get() = genre
    val originalStatus: Int get() = status

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
    var chapter_number: Float
        get() = episode_number
        set(value) { episode_number = value }
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
    override var title: String = ""
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
 * Constructors match Anikku source-api Video and Hoster at the JVM boundary.
 * Extra legacy constructors are retained to avoid breaking existing APKs.
 */
data class Track(val url: String, val lang: String)

enum class ChapterType { Opening, Ending, Recap, MixedOp, Other }

data class TimeStamp(
    val start: Double,
    val end: Double,
    val name: String,
    val type: ChapterType = ChapterType.Other
)

/** Binary-compatible Anikku 1.6 Video model.
 * Keep the current 14-property default-arguments constructor for extension
 * bytecode calling <init>(..., int, DefaultConstructorMarker). Also keep the
 * old AnimeStream constructor/copy signatures for existing installed APKs.
 */
open class Video(
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
) {
    // Older providers still rely on videoPageUrl when resolving legacy URLs.
    private var legacyVideoPageUrl: String = ""
    val videoPageUrl: String get() = legacyVideoPageUrl

    @Deprecated("Use videoTitle")
    val quality: String get() = videoTitle
    @Deprecated("Use videoPageUrl")
    val url: String get() = videoPageUrl

    @Transient @Volatile
    var status: State = State.QUEUE
    enum class State { QUEUE, LOAD_VIDEO, READY, ERROR }

    val memo: kotlinx.serialization.json.JsonObject
        get() = kotlinx.serialization.json.JsonObject(emptyMap())

    companion object {
        const val MPV_ARGS_TAG = "ANIYOMI_MPV_ARGS"
    }

    // Previous AnimeStream versions used a 12-property primary constructor.
    // HIDDEN retains its JVM ABI and generated Kotlin default-mask signature,
    // without making Video(...) ambiguous in new Kotlin source.
    @Deprecated("Binary compatibility: pre-1.6 Video ABI", level = DeprecationLevel.HIDDEN)
    constructor(
        videoUrl: String = "",
        videoTitle: String = "",
        resolution: Int? = null,
        bitrate: Int? = null,
        headers: okhttp3.Headers? = null,
        preferred: Boolean = false,
        subtitleTracks: List<Track> = emptyList(),
        audioTracks: List<Track> = emptyList(),
        timestamps: List<TimeStamp> = emptyList(),
        internalData: String = "",
        initialized: Boolean = false,
        videoPageUrl: String = "",
    ) : this(
        videoUrl, videoTitle, resolution, bitrate, headers, preferred,
        subtitleTracks, audioTracks, timestamps,
        emptyList(), emptyList(), emptyList(), internalData, initialized
    ) {
        legacyVideoPageUrl = videoPageUrl
    }

    // Historical Aniyomi URL-first constructor.
    constructor(
        url: String,
        quality: String,
        videoUrl: String?,
        headers: okhttp3.Headers? = null,
        subtitleTracks: List<Track> = emptyList(),
        audioTracks: List<Track> = emptyList(),
    ) : this(
        videoUrl = videoUrl ?: "null", videoTitle = quality, headers = headers,
        subtitleTracks = subtitleTracks, audioTracks = audioTracks,
    ) {
        legacyVideoPageUrl = url
    }

    // Earlier ten-property source-api constructor without mpv/ffmpeg args.
    constructor(
        videoUrl: String, videoTitle: String, resolution: Int?, bitrate: Int?,
        headers: okhttp3.Headers?, preferred: Boolean,
        subtitleTracks: List<Track>, audioTracks: List<Track>,
        timestamps: List<TimeStamp>, internalData: String,
    ) : this(
        videoUrl, videoTitle, resolution, bitrate, headers, preferred,
        subtitleTracks, audioTracks, timestamps,
        emptyList(), emptyList(), emptyList(), internalData, false
    )

    @Suppress("UNUSED_PARAMETER")
    constructor(
        url: String, quality: String, videoUrl: String?,
        uri: android.net.Uri? = null, headers: okhttp3.Headers? = null,
    ) : this(url, quality, videoUrl, headers)

    // Legacy 15-field compatibility overload (memo is not part of the
    // upstream 14-field default-argument constructor).
    @Suppress("UNUSED_PARAMETER")
    constructor(
        videoUrl: String, videoTitle: String, resolution: Int?, bitrate: Int?,
        headers: okhttp3.Headers?, preferred: Boolean,
        subtitleTracks: List<Track>, audioTracks: List<Track>,
        timestamps: List<TimeStamp>, mpvArgs: List<Pair<String, String>>,
        ffmpegStreamArgs: List<Pair<String, String>>,
        ffmpegVideoArgs: List<Pair<String, String>>,
        internalData: String, initialized: Boolean,
        memo: kotlinx.serialization.json.JsonObject,
    ) : this(
        videoUrl, videoTitle, resolution, bitrate, headers, preferred,
        subtitleTracks, audioTracks, timestamps,
        mpvArgs, ffmpegStreamArgs, ffmpegVideoArgs, internalData, initialized
    )

    // Match Anikku Video.copy / copy$default generated for the 14 fields.
    fun copy(
        videoUrl: String = this.videoUrl,
        videoTitle: String = this.videoTitle,
        resolution: Int? = this.resolution,
        bitrate: Int? = this.bitrate,
        headers: okhttp3.Headers? = this.headers,
        preferred: Boolean = this.preferred,
        subtitleTracks: List<Track> = this.subtitleTracks,
        audioTracks: List<Track> = this.audioTracks,
        timestamps: List<TimeStamp> = this.timestamps,
        mpvArgs: List<Pair<String, String>> = this.mpvArgs,
        ffmpegStreamArgs: List<Pair<String, String>> = this.ffmpegStreamArgs,
        ffmpegVideoArgs: List<Pair<String, String>> = this.ffmpegVideoArgs,
        internalData: String = this.internalData,
        initialized: Boolean = this.initialized,
    ) = Video(
        videoUrl, videoTitle, resolution, bitrate, headers, preferred,
        subtitleTracks, audioTracks, timestamps,
        mpvArgs, ffmpegStreamArgs, ffmpegVideoArgs, internalData, initialized
    ).also { it.legacyVideoPageUrl = legacyVideoPageUrl }

    // Maintain the older 12-field copy$default binary signature.
    @Deprecated("Binary compatibility: pre-1.6 Video.copy ABI", level = DeprecationLevel.HIDDEN)
    fun copy(
        videoUrl: String = this.videoUrl,
        videoTitle: String = this.videoTitle,
        resolution: Int? = this.resolution,
        bitrate: Int? = this.bitrate,
        headers: okhttp3.Headers? = this.headers,
        preferred: Boolean = this.preferred,
        subtitleTracks: List<Track> = this.subtitleTracks,
        audioTracks: List<Track> = this.audioTracks,
        timestamps: List<TimeStamp> = this.timestamps,
        internalData: String = this.internalData,
        initialized: Boolean = this.initialized,
        videoPageUrl: String = this.videoPageUrl,
    ) = Video(
        videoUrl, videoTitle, resolution, bitrate, headers, preferred,
        subtitleTracks, audioTracks, timestamps,
        emptyList(), emptyList(), emptyList(), internalData, initialized
    ).also { it.legacyVideoPageUrl = videoPageUrl }
}

/** Match the binary constructors generated by Anikku source-api Hoster.
 * In particular, extensions compiled with Kotlin defaults call
 * (String, String, List, String, boolean, int, DefaultConstructorMarker).
 * Retain the old four-field constructor and its default-mask bridge for
 * already installed extensions compiled against earlier AnimeStream builds.
 */
open class Hoster(
    val hosterUrl: String = "",
    val hosterName: String = "",
    val videoList: List<Video>? = null,
    val internalData: String = "",
    val lazy: Boolean = false,
) {
    @Transient @Volatile
    var status: State = State.IDLE

    enum class State { IDLE, LOADING, READY, ERROR }

    val memo: kotlinx.serialization.json.JsonObject
        get() = kotlinx.serialization.json.JsonObject(emptyMap())

    // Binary-only compatibility overload; HIDDEN avoids ambiguous Kotlin
    // overload resolution while still emitting the original 4-arg $default.
    @Deprecated("Binary compatibility with older four-field Hoster", level = DeprecationLevel.HIDDEN)
    constructor(
        hosterUrl: String = "",
        hosterName: String = "",
        videoList: List<Video>? = null,
        internalData: String = "",
    ) : this(hosterUrl, hosterName, videoList, internalData, false)

    @Suppress("UNUSED_PARAMETER")
    constructor(
        hosterUrl: String, hosterName: String, videoList: List<Video>?,
        internalData: String, lazy: Boolean, memo: kotlinx.serialization.json.JsonObject
    ) : this(hosterUrl, hosterName, videoList, internalData, lazy)

    fun copy(
        hosterUrl: String = this.hosterUrl,
        hosterName: String = this.hosterName,
        videoList: List<Video>? = this.videoList,
        internalData: String = this.internalData,
        lazy: Boolean = this.lazy,
    ) = Hoster(hosterUrl, hosterName, videoList, internalData, lazy)

    // Match the older copy$default signature for binary callers.
    @Deprecated("Binary compatibility with older four-field Hoster.copy", level = DeprecationLevel.HIDDEN)
    fun copy(
        hosterUrl: String = this.hosterUrl,
        hosterName: String = this.hosterName,
        videoList: List<Video>? = this.videoList,
        internalData: String = this.internalData,
    ) = Hoster(hosterUrl, hosterName, videoList, internalData, lazy)

    companion object {
        const val NO_HOSTER_LIST = "no_hoster_list"
        fun List<Video>.toHosterList(): List<Hoster> =
            listOf(Hoster(hosterName = NO_HOSTER_LIST, videoList = this))
    }
}
