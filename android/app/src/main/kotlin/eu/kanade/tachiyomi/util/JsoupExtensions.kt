package eu.kanade.tachiyomi.util

import okhttp3.Response
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import java.io.IOException

/**
 * Aniyomi source-api Jsoup helpers.
 *
 * These exact top-level names compile into JsoupExtensionsKt, which
 * externally installed Aniyomi extensions reference by JVM name.
 */
fun Element.selectText(css: String, defaultValue: String? = null): String? {
    return select(css).first()?.text() ?: defaultValue
}

fun Element.selectInt(css: String, defaultValue: Int = 0): Int {
    return select(css).first()?.text()?.toInt() ?: defaultValue
}

fun Element.attrOrText(css: String): String {
    return if (css != "text") attr(css) else text()
}

fun Response.asJsoup(html: String? = null): Document {
    return Jsoup.parse(html ?: (body?.string() ?: throw IOException("HTTP response has no body")), request.url.toString())
}
