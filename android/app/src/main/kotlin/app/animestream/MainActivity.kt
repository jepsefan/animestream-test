package app.animestream

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
        if (rawClass.isNullOrBlank()) return mapOf("status" to "no_source_class")
        val expected = if (rawClass.startsWith(".")) packageName + rawClass else rawClass
        val classes = mutableListOf<String>()
        try {
            val dex = DexFile(info.sourceDir)
            try {
                val names = dex.entries()
                while (names.hasMoreElements()) {
                    classes.add(names.nextElement())
                }
            } finally {
                dex.close()
            }
        } catch (e: Throwable) {
            return mapOf("status" to "dex_scan_failed", "className" to expected,
                "error" to (e.javaClass.simpleName + ": " + (e.message ?: "")))
        }
        val simpleName = rawClass.substringAfterLast('.')
        val candidates = classes.filter { it == expected || it.substringAfterLast('.') == simpleName }.take(15)
        val target = if (expected in classes) expected else candidates.firstOrNull()
        if (target == null) return mapOf("status" to "class_not_in_dex",
            "className" to expected, "dexClassCount" to classes.size,
            "candidates" to candidates.joinToString(", "))
        return try {
            val loader = DexClassLoader(info.sourceDir, codeCacheDir.absolutePath,
                info.nativeLibraryDir, javaClass.classLoader)
            val clazz = Class.forName(target, false, loader)
            mapOf("status" to "class_found", "className" to clazz.name,
                "dexClassCount" to classes.size, "candidates" to candidates.joinToString(", "))
        } catch (e: Throwable) {
            val chain = generateSequence(e) { it.cause }.take(6).joinToString(" -> ") {
                it.javaClass.simpleName + ": " + (it.message ?: "")
            }
            mapOf("status" to "class_load_failed", "className" to target,
                "dexClassCount" to classes.size, "candidates" to candidates.joinToString(", "),
                "error" to chain, "classInDex" to (target in classes))
        }
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
