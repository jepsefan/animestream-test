package app.animestream

/**
 * Safe diagnostic metadata for extension linkage failures.
 * No exception messages or full stack traces are sent to Flutter:
 * they may contain signed video URLs, headers, cookies or OAuth tokens.
 */
internal class ExtensionStreamStageFailure(
    val stageName: String,
    cause: Throwable
) : RuntimeException(cause)

internal class ExtensionDiscoveryStageFailure(
    val stageName: String,
    cause: Throwable
) : RuntimeException(cause)

internal object ExtensionLinkageDiagnostics {
    private val allowedPrefixes = listOf(
        "eu.kanade.", "keiyoushi.", "kotlin.", "kotlinx.", "java.",
        "javax.", "android.", "androidx.", "okhttp3.", "okio.",
        "org.jsoup.", "org.json.", "com.google.", "com.squareup.",
        "rx.", "io.reactivex.", "uy.kohesive."
    )
    private val token = Regex("""[A-Za-z_$][A-Za-z0-9_$]*(?:[./][A-Za-z_$][A-Za-z0-9_$]*)+;?""")
    private val identifier = Regex("""[A-Za-z_$][A-Za-z0-9_$]*(?:\.[A-Za-z_$][A-Za-z0-9_$]*)+""")

    private fun safeClass(raw: String): String? {
        val cleaned = raw.trim().removeSuffix(";").replace('/', '.')
        if (cleaned.length !in 8..180 || !identifier.matches(cleaned)) return null
        if (allowedPrefixes.none { cleaned.startsWith(it) }) return null
        return cleaned
    }

    fun describe(error: Throwable): Map<String, Any?> = describeInternal(error, false)

    fun describeDiscovery(error: Throwable): Map<String, Any?> =
        describeInternal(error, true)

    private fun describeInternal(error: Throwable, discovery: Boolean): Map<String, Any?> {
        val chain = mutableListOf<Throwable>()
        val seen = java.util.Collections.newSetFromMap(
            java.util.IdentityHashMap<Throwable, Boolean>()
        )
        var current: Throwable? = error
        while (current != null && chain.size < 10 && seen.add(current)) {
            chain.add(current)
            current = when (current) {
                is java.lang.reflect.InvocationTargetException ->
                    current.targetException ?: current.cause
                else -> current.cause
            }
        }

        val missing = linkedSetOf<String>()
        for (cause in chain) {
            if (cause is ClassNotFoundException ||
                cause is NoClassDefFoundError ||
                cause is ExceptionInInitializerError
            ) {
                // Messages are scanned locally for class names only. Never
                // return the message itself (it could contain a URL/token).
                for (match in token.findAll(cause.message.orEmpty().take(1500))) {
                    safeClass(match.value)?.let(missing::add)
                }
            }
        }

        val stage = if (discovery)
            chain.filterIsInstance<ExtensionDiscoveryStageFailure>().firstOrNull()?.stageName
        else
            chain.filterIsInstance<ExtensionStreamStageFailure>().firstOrNull()?.stageName
        val frames = chain.asSequence().flatMap { it.stackTrace.asSequence() }
            .filter { frame ->
                frame.className.startsWith("eu.kanade.") ||
                frame.className.startsWith("keiyoushi.") ||
                frame.className.startsWith("app.animestream.")
            }
            .map { it.className + "." + it.methodName }
            .distinct().take(6).toList()

        return mapOf(
            "status" to if (discovery) "failed" else "stream_list_failed",
            "errorType" to (chain.firstOrNull { it !is ExtensionDiscoveryStageFailure &&
                it !is ExtensionStreamStageFailure }
                ?.javaClass?.simpleName ?: "UnknownError"),
            "failureCategory" to if (chain.any { it is LinkageError ||
                it is ClassNotFoundException }) "linkage"
                else if (chain.any { it is java.lang.reflect.InvocationTargetException })
                    "extension_constructor"
                else if (chain.any { it is IllegalStateException })
                    "invalid_source_state" else "extension_runtime",
            "errorTypes" to chain.map { it.javaClass.simpleName },
            "missingClasses" to missing.toList().take(8),
            "failureStage" to (stage ?: "unknown"),
            "hostFrames" to frames
        )
    }
}
