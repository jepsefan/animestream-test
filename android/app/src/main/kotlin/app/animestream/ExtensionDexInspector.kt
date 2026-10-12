package app.animestream

import java.io.File
import java.util.zip.ZipFile

/**
 * Read DEX class_def metadata directly from installed APKs.
 * Does not load, initialize or execute third-party classes.
 */
internal object ExtensionDexInspector {
    data class ClassInfo(val source: String, val superClass: String?,
                         val interfaces: List<String>, val accessFlags: Int)
    private fun u16(b: ByteArray, p: Int): Int {
        require(p >= 0 && p + 2 <= b.size)
        return (b[p].toInt() and 255) or ((b[p + 1].toInt() and 255) shl 8)
    }
    private fun u32(b: ByteArray, p: Int): Int {
        require(p >= 0 && p + 4 <= b.size)
        return (b[p].toInt() and 255) or ((b[p + 1].toInt() and 255) shl 8) or
            ((b[p + 2].toInt() and 255) shl 16) or ((b[p + 3].toInt() and 255) shl 24)
    }
    private fun stringAt(b: ByteArray, offset: Int): String {
        var p = offset
        var shift = 0
        do {
            require(p < b.size && shift <= 28)
            val byte = b[p++].toInt() and 255
            shift += 7
            if ((byte and 128) == 0) break
        } while (true)
        val begin = p
        while (p < b.size && b[p] != 0.toByte()) p++
        require(p < b.size)
        // DEX uses modified UTF-8; descriptors are ASCII.
        return String(b, begin, p - begin, Charsets.UTF_8)
    }
    private fun descriptor(value: String): String =
        if (value.startsWith("L") && value.endsWith(";"))
            value.substring(1, value.length - 1).replace('/', '.') else value

    fun inspect(apks: List<String>, target: String): Pair<ClassInfo?, List<String>> {
        val errors = mutableListOf<String>()
        for (apk in apks) {
            try {
                ZipFile(File(apk)).use { zip ->
                    val entries = zip.entries()
                    while (entries.hasMoreElements()) {
                        val entry = entries.nextElement()
                        if (!Regex("classes(\\d*)\\.dex").matches(entry.name)) continue
                        try {
                            val b = zip.getInputStream(entry).use { it.readBytes() }
                            require(b.size >= 112 && String(b, 0, 4, Charsets.US_ASCII) == "dex\n") {
                                "Invalid DEX header"
                            }
                            val stringsSize = u32(b, 56)
                            val stringsOff = u32(b, 60)
                            val typesSize = u32(b, 64)
                            val typesOff = u32(b, 68)
                            val defsSize = u32(b, 96)
                            val defsOff = u32(b, 100)
                            require(stringsSize in 0..1000000 && typesSize in 0..1000000 &&
                                defsSize in 0..1000000 && stringsOff.toLong() + stringsSize.toLong() * 4 <= b.size &&
                                typesOff.toLong() + typesSize.toLong() * 4 <= b.size &&
                                defsOff.toLong() + defsSize.toLong() * 32 <= b.size)
                            fun type(index: Int): String {
                                require(index in 0 until typesSize)
                                val stringIndex = u32(b, typesOff + index * 4)
                                require(stringIndex in 0 until stringsSize)
                                return descriptor(stringAt(b, u32(b, stringsOff + stringIndex * 4)))
                            }
                            for (i in 0 until defsSize) {
                                val p = defsOff + i * 32
                                val classIndex = u32(b, p)
                                if (type(classIndex) != target) continue
                                val accessFlags = u32(b, p + 4)
                                val superIndex = u32(b, p + 8)
                                val superClass = if (superIndex == -1) null else type(superIndex)
                                val interfacesOff = u32(b, p + 12)
                                val interfaces = if (interfacesOff == 0) emptyList() else {
                                    val count = u32(b, interfacesOff)
                                    require(count in 0..4096 && interfacesOff.toLong() + 4L + count * 2L <= b.size)
                                    (0 until count).map { type(u16(b, interfacesOff + 4 + it * 2)) }
                                }
                                return ClassInfo("${File(apk).name}/${entry.name}", superClass, interfaces, accessFlags) to errors
                            }
                        } catch (e: Exception) {
                            errors.add("${File(apk).name}/${entry.name}: ${e.javaClass.simpleName}: ${e.message}")
                        }
                    }
                }
            } catch (e: Exception) {
                errors.add("${File(apk).name}: ${e.javaClass.simpleName}: ${e.message}")
            }
        }
        if (errors.isEmpty()) errors.add("Target class definition not found in scanned classes*.dex files")
        return null to errors
    }
}
