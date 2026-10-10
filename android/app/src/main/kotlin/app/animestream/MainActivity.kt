package app.animestream

import android.widget.Toast
import android.content.pm.PackageManager
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

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        extensionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "animestream.app/aniyomi_extensions")
        extensionChannel.setMethodCallHandler { call, result ->
            when (call.method) {
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
        val flags = PackageManager.GET_META_DATA.toLong()
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(PackageManager.PackageInfoFlags.of(flags))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(PackageManager.GET_META_DATA)
        }
        return packages.mapNotNull { pkg ->
            val info = pkg.applicationInfo ?: return@mapNotNull null
            val metadata = info.metaData ?: return@mapNotNull null
            val sourceClass = metadata.getString("tachiyomi.animeextension.class")
            val sourceFactory = metadata.getString("tachiyomi.animeextension.factory")
            if (sourceClass.isNullOrBlank() && sourceFactory.isNullOrBlank()) return@mapNotNull null
            mapOf(
                "packageName" to pkg.packageName,
                "name" to pm.getApplicationLabel(info).toString(),
                "version" to (pkg.versionName ?: ""),
                "sourceClass" to sourceClass,
                "sourceFactory" to sourceFactory,
                "status" to "detected_not_loaded"
            )
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
