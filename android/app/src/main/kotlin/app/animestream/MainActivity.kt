package app.animestream

import dalvik.system.PathClassLoader
import dalvik.system.DexClassLoader
import dalvik.system.DexFile
import android.widget.Toast
import android.content.pm.PackageManager
import android.content.pm.FeatureInfo
import android.os.Build
import android.os.Looper
import android.os.Handler
import androidx.annotation.NonNull

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {

    private lateinit var channel: MethodChannel
    private lateinit var extensionChannel: MethodChannel
    private lateinit var assRenderChannel: MethodChannel
    private val externalAssRenderer = ExternalAssRenderer()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        externalAssRenderer.attach(flutterEngine.renderer)
        assRenderChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "animestream.app/assrender")
        assRenderChannel.setMethodCallHandler(externalAssRenderer)
        extensionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "animestream.app/aniyomi_extensions")
        extensionChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "inspectExtensionClass" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("INVALID_PACKAGE", "Missing packageName", null)
                    } else {
                        try {
                            result.success(inspectExtensionClass(packageName))
                        } catch (e: Exception) {
                            result.error("CLASS_INSPECTION_FAILED", e.toString(), null)
                        }
                    }
                }
                "listInstalledExtensions" -> {
                    try {
                        result.success(listInstalledAnimeExtensions())
                    } catch (e: Exception) {
                        result.error("EXTENSION_SCAN_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "animestream.app/utils")
        channel.setMethodCallHandler {
                call, result ->
            when (call.method) {
                "showToast" -> {
                val message = call.argument<String>("message")
                if(message == null || message.length == 0) {
                    result.error("MESSAGE_NOT_PROVIDED", "MESSAGE IS NULL OR EMPTY", null)
                }
                showToast(message ?: "")
                }
                else -> result.notImplemented()
            }
        }
    }

    // Metadata-only discovery. No third-party APK code is executed here.
    // Android 11+ package visibility is declared in AndroidManifest.xml.
    private fun listInstalledAnimeExtensions(): List<Map<String, Any?>> {
        val pm = packageManager
        val flags = (PackageManager.GET_META_DATA or PackageManager.GET_CONFIGURATIONS).toLong()
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(PackageManager.PackageInfoFlags.of(flags))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(PackageManager.GET_META_DATA or PackageManager.GET_CONFIGURATIONS)
        }
        return packages.mapNotNull { pkg ->
            val info = pkg.applicationInfo ?: return@mapNotNull null
            val metadata = info.metaData
            val sourceClass = metadata?.getString("tachiyomi.animeextension.class")
            val sourceFactory = metadata?.getString("tachiyomi.animeextension.factory")
            val hasExtensionFeature = pkg.reqFeatures?.any {
                it.name == "tachiyomi.animeextension"
            } == true
            if (!hasExtensionFeature && sourceClass.isNullOrBlank() && sourceFactory.isNullOrBlank()) return@mapNotNull null
            mapOf(
                "packageName" to pkg.packageName,
                "name" to pm.getApplicationLabel(info).toString(),
                "version" to (pkg.versionName ?: ""),
                "sourceClass" to sourceClass,
                "sourceFactory" to sourceFactory,
                "hasExtensionFeature" to hasExtensionFeature,
                "status" to "detected_not_loaded"
            )
        }
    }

    // Diagnostic only: enumerate APK DEX classes and resolve without initialization.
    // This does not instantiate or execute extension source classes.
    private fun inspectExtensionClass(packageName: String): Map<String, Any?> {
        val pm = packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getApplicationInfo(packageName, PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        }
        val rawClass = info.metaData?.getString("tachiyomi.animeextension.class")
        val rawFactory = info.metaData?.getString("tachiyomi.animeextension.factory")
        if (rawClass.isNullOrBlank() && rawFactory.isNullOrBlank()) return mapOf("status" to "no_source_class")
        val declaredEntries = listOfNotNull(rawClass, rawFactory)
            .flatMap { it.split(';', ',').map { name -> name.trim() }.filter { name -> name.isNotEmpty() } }
            .map { name -> if (name.startsWith(".")) packageName + name else name }.distinct()
        val expected = declaredEntries.first()
        val apkPaths = listOfNotNull(info.sourceDir) + (info.splitSourceDirs?.toList() ?: emptyList())
        val classes = mutableListOf<String>()
        val scanErrors = mutableListOf<String>()
        val dexInventory = mutableListOf<String>()
        for (apk in apkPaths) {
            try {
                val dex = DexFile(apk)
                try {
                    val names = dex.entries()
                    var count = 0
                    var exactFound = false
                    while (names.hasMoreElements()) {
                        val name = names.nextElement()
                        classes.add(name)
                        count++
                        if (name == expected) exactFound = true
                    }
                    dexInventory.add("${apk.substringAfterLast('/')}: $count classes, declaredClassPresent=$exactFound")
                } finally {
                    dex.close()
                }
            } catch (e: Throwable) {
                scanErrors.add("${apk.substringAfterLast('/')}: ${e.javaClass.simpleName}: ${e.message}")
            }
        }
        val candidates = classes.filter { name -> declaredEntries.any { entry -> name == entry || name.substringAfterLast('.') == entry.substringAfterLast('.') } }.take(25)
        val target = declaredEntries.firstOrNull { it in classes } ?: candidates.firstOrNull()
        val base = mutableMapOf<String, Any?>(
            "className" to expected,
            "dexClassCount" to classes.size,
            "declaredClassInDex" to (expected in classes),
            "dexInventory" to dexInventory.joinToString("\\n"),
            "declaredClass" to rawClass,
            "declaredFactory" to rawFactory,
            "declaredEntryPoints" to declaredEntries.joinToString(", "),
            "entryPointsInDex" to declaredEntries.filter { it in classes }.joinToString(", "),
            "extensionPackageClasses" to classes.filter { it.startsWith(packageName) }.take(30).joinToString(", "),
            "apkCount" to apkPaths.size,
            "apkFiles" to apkPaths.map { it.substringAfterLast('/') }.joinToString(", "),
            "dexScanErrors" to scanErrors.joinToString("\\n"),
            "candidates" to candidates.joinToString(", "),
            "classInDex" to (expected in classes),
            "hostApiPresent" to try {
                Class.forName("eu.kanade.tachiyomi.animesource.AnimeSource", false, javaClass.classLoader)
                true
            } catch (_: Throwable) { false }
        )
        if (target == null) {
            base["status"] = "class_not_in_dex"
            base["diagnosis"] = "Declared entry point absent from scanned base/split APK DEX files"
            return base
        }
        // Diagnostic only: do not initialize or instantiate untrusted extension classes.
        // Compare two loaders against the same installed base/split APK paths.
        val dexPath = apkPaths.joinToString(java.io.File.pathSeparator)
        val loaders = listOf(
            "DexClassLoader" to DexClassLoader(dexPath, codeCacheDir.absolutePath,
                info.nativeLibraryDir, javaClass.classLoader),
            "PathClassLoader" to PathClassLoader(dexPath, info.nativeLibraryDir,
                javaClass.classLoader)
        )
        val outcomes = mutableMapOf<String, String>()
        var resolvedBy: String? = null
        var firstError: Throwable? = null
        for ((name, loader) in loaders) {
            try {
                val clazz = Class.forName(target, false, loader)
                outcomes[name] = "class_found: ${clazz.name}"
                if (resolvedBy == null) resolvedBy = name
            } catch (e: Throwable) {
                if (firstError == null) firstError = e
                val causes = generateSequence(e) { it.cause }.take(8).toList()
                outcomes[name] = causes.joinToString(" -> ") {
                    it.javaClass.simpleName + ": " + (it.message ?: "")
                }
            }
        }
        base["dexClassLoaderResult"] = outcomes["DexClassLoader"]
        base["pathClassLoaderResult"] = outcomes["PathClassLoader"]
        base["resolvedByLoader"] = resolvedBy
        if (resolvedBy != null) {
            base["status"] = "class_found"
            base["className"] = target
            base["diagnosis"] = "Class resolved without initialization by $resolvedBy. This does not establish executable extension support."
            return base
        }
        val e = firstError ?: IllegalStateException("Both class loaders failed without a reported cause")
        val causes = generateSequence(e) { it.cause }.take(8).toList()
        val chain = causes.joinToString(" -> ") {
            it.javaClass.simpleName + ": " + (it.message ?: "")
        }
        val missing = causes.firstOrNull {
            it is ClassNotFoundException || it is NoClassDefFoundError
        }?.message
        val missingHostApi = missing?.contains("eu.kanade.tachiyomi.animesource.") == true ||
            missing?.contains("eu/kanade/tachiyomi/animesource/") == true ||
            missing?.contains("eu.kanade.tachiyomi.source.") == true ||
            missing?.contains("eu/kanade/tachiyomi/source/") == true
        base["status"] = if (missingHostApi) "missing_host_api" else "class_load_failed"
        base["className"] = target
        base["error"] = chain
        base["missingDependency"] = missing?.takeUnless { it == target || it == target.replace('.', '/') }
        base["targetClassInDex"] = target in classes
        base["dependencyClassInDex"] = missing?.replace('/', '.')?.let { it in classes }
        base["entryPointResolutionFailed"] = missing == target || missing == target.replace('.', '/')
        base["exceptionTypes"] = causes.joinToString(" -> ") { it.javaClass.name }
        base["rootCause"] = causes.lastOrNull()?.let {
            it.javaClass.name + ": " + (it.message ?: "")
        }
        base["diagnosis"] = if (missingHostApi)
            "A known Aniyomi/Tachiyomi host API class could not be resolved"
            else "Both loaders failed. Compare dexClassLoaderResult and pathClassLoaderResult; a DEX inventory hit alone does not guarantee a loadable class."
        return base
    }

    override fun onUserLeaveHint() {
         super.onUserLeaveHint()
         channel.invokeMethod("onUserLeaveHint", null);
    }

    fun showToast(message: String) {
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
        }
    }
}
