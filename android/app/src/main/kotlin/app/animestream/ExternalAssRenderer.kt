package app.animestream

import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.github.assrender.AssDirectBridge
import java.io.ByteArrayOutputStream

/**
 * External ASS/SSA subtitle renderer for AnimeStream's Flutter SubViewer.
 * Requires the assrender Android AAR to be added to the app's Gradle dependencies.
 * Never changes Better Player or its ExoPlayer instance.
 */
class ExternalAssRenderer : MethodChannel.MethodCallHandler {
    private var handle: Long = 0
    private var width = 0
    private var height = 0
    private var bitmap: Bitmap? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "load" -> {
                    release()
                    val script = call.argument<ByteArray>("script")
                        ?: throw IllegalArgumentException("Missing ASS script")
                    width = (call.argument<Int>("width") ?: 1280).coerceIn(1, 3840)
                    height = (call.argument<Int>("height") ?: 720).coerceIn(1, 2160)
                    handle = AssDirectBridge.nativeInit(width, height, 1.0f)
                    if (handle == 0L) throw IllegalStateException("libass initialization failed")
                    if (AssDirectBridge.nativeLoadScript(handle, script) != 0) {
                        release()
                        throw IllegalArgumentException("Invalid ASS/SSA script")
                    }
                    bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    result.success(null)
                }
                "render" -> {
                    val target = bitmap
                    if (handle == 0L || target == null) {
                        result.success(null)
                    } else {
                        val timeMs = (call.argument<Number>("timeMs") ?: 0).toLong()
                        if (!AssDirectBridge.nativeRender(handle, timeMs, target)) {
                            result.success(null)
                        } else {
                            val output = ByteArrayOutputStream()
                            target.compress(Bitmap.CompressFormat.PNG, 100, output)
                            result.success(output.toByteArray())
                        }
                    }
                }
                "dispose" -> {
                    release()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("ASS_RENDER_FAILED", e.message, null)
        }
    }

    private fun release() {
        if (handle != 0L) {
            AssDirectBridge.nativeDestroy(handle)
            handle = 0
        }
        bitmap?.recycle()
        bitmap = null
    }
}
