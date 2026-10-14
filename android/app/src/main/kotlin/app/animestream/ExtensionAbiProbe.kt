package app.animestream

import eu.kanade.tachiyomi.animesource.AnimeCatalogueSource
import eu.kanade.tachiyomi.animesource.AnimeSource
import eu.kanade.tachiyomi.animesource.AnimeSourceFactory
import eu.kanade.tachiyomi.animesource.model.*
import eu.kanade.tachiyomi.animesource.online.AnimeHttpSource
import kotlin.coroutines.Continuation
import okhttp3.Headers
import rx.Observable

/**
 * Reflection-only check of common JVM descriptors referenced by extension APKs.
 * Does not load or run third-party APK code and never includes media URLs.
 */
internal object ExtensionAbiProbe {
    fun inspect(): Map<String, Any?> {
        val checks = mutableListOf<Map<String, Any?>>()
        fun check(label: String, test: () -> Unit) {
            val failure = try {
                test()
                null
            } catch (e: ReflectiveOperationException) {
                e.javaClass.simpleName
            } catch (e: LinkageError) {
                e.javaClass.simpleName
            }
            checks.add(mapOf("name" to label, "ok" to (failure == null), "errorType" to failure))
        }

        val list = List::class.java
        val nullableInt = Int::class.javaObjectType
        val boolean = Boolean::class.javaPrimitiveType!!
        val integer = Int::class.javaPrimitiveType!!
        val flt = Float::class.javaPrimitiveType!!
        val lng = Long::class.javaPrimitiveType!!
        val string = String::class.java
        val continuation = Continuation::class.java

        check("Video upstream 12-argument constructor") {
            Video::class.java.getConstructor(
                string, string, nullableInt, nullableInt, Headers::class.java,
                boolean, list, list, list, string, boolean, string
            )
        }
        check("Video legacy URL/quality constructor") {
            Video::class.java.getConstructor(
                string, string, string, Headers::class.java, list, list
            )
        }
        check("Hoster upstream four-argument constructor") {
            Hoster::class.java.getConstructor(string, string, list, string)
        }
        check("Hoster video getter") {
            Hoster::class.java.getMethod("getVideoList")
        }
        check("Video subtitle and audio getters") {
            Video::class.java.getMethod("getSubtitleTracks")
            Video::class.java.getMethod("getAudioTracks")
        }
        check("AnimeFilter.Select subclass") {
            Class.forName(AnimeFilter::class.java.name + "\$Select", false,
                AnimeFilter::class.java.classLoader)
        }
        check("AnimeFilter.Sort subclass") {
            Class.forName(AnimeFilter::class.java.name + "\$Sort", false,
                AnimeFilter::class.java.classLoader)
        }
        check("SAnime originalTitle getter") {
            SAnime::class.java.getMethod("getOriginalTitle")
        }
        check("SEpisode chapter_number getter") {
            SEpisode::class.java.getMethod("getChapter_number")
        }
        check("AnimeSource suspend getEpisodeList") {
            AnimeSource::class.java.getMethod("getEpisodeList", SAnime::class.java, continuation)
        }
        check("AnimeSource suspend getHosterList") {
            AnimeSource::class.java.getMethod("getHosterList", SEpisode::class.java, continuation)
        }
        check("AnimeCatalogueSource suspend search") {
            AnimeCatalogueSource::class.java.getMethod(
                "getSearchAnime", integer, string, AnimeFilterList::class.java, continuation)
        }
        check("AnimeCatalogueSource legacy Rx search") {
            AnimeCatalogueSource::class.java.getMethod(
                "fetchSearchAnime", integer, string, AnimeFilterList::class.java)
        }
        check("AnimeSourceFactory createSources") {
            AnimeSourceFactory::class.java.getMethod("createSources")
        }
        check("AnimeHttpSource headers accessor") {
            AnimeHttpSource::class.java.getMethod("getHeaders")
        }

        val failed = checks.count { it["ok"] != true }
        return mapOf(
            "status" to if (failed == 0) "host_abi_descriptors_present" else "host_abi_missing_descriptors",
            "checked" to checks.size,
            "failed" to failed,
            "checks" to checks
        )
    }
}
