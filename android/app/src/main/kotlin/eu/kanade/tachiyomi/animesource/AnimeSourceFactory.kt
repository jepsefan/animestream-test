package eu.kanade.tachiyomi.animesource

/** Binary contract used by multi-source Aniyomi extension APKs. */
interface AnimeSourceFactory {
    fun createSources(): List<AnimeSource>
}
