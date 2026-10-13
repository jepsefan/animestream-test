package app.animestream

internal data class ExtensionSearchResult(
    val status: String,
    val query: String,
    val results: List<Map<String, String>> = emptyList()
)
