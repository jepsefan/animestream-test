package app.animestream

import dalvik.system.DexClassLoader

/**
 * Loads classes belonging to an installed extension from its own APK before
 * asking AnimeStream's parent loader. All other classes (including the host
 * Aniyomi API and Android/framework types) use standard parent-first loading.
 *
 * Used only for class-resolution diagnostics, never for extension execution.
 */
internal class ExtensionIsolatedClassLoader(
    dexPath: String,
    optimizedDirectory: String,
    librarySearchPath: String?,
    parent: ClassLoader,
    private val extensionClassNames: Set<String>
) : DexClassLoader(dexPath, optimizedDirectory, librarySearchPath, parent) {

    override fun loadClass(name: String, resolve: Boolean): Class<*> {
        synchronized(this) {
            findLoadedClass(name)?.let {
                if (resolve) resolveClass(it)
                return it
            }
            if (name in extensionClassNames) {
                try {
                    val local = findClass(name)
                    if (resolve) resolveClass(local)
                    return local
                } catch (_: ClassNotFoundException) {
                    // The class may legitimately be supplied by the host.
                }
            }
            return super.loadClass(name, resolve)
        }
    }
}
