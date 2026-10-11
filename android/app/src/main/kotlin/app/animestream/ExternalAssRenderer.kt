package app.animestream

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.SurfaceTexture
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import io.flutter.view.TextureRegistry
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.github.assrender.AssDirectBridge
import java.util.concurrent.Executors

/**
 * ASS frames are composited directly onto an Android SurfaceTexture consumed by
 * Flutter Texture. No per-frame PNG compression, MethodChannel pixel transfer,
 * or Flutter image decoding. Native work runs on a serial worker thread.
 */
class ExternalAssRenderer : MethodChannel.MethodCallHandler {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var registry: TextureRegistry? = null
    private var entry: TextureRegistry.SurfaceTextureEntry? = null
    private var surface: Surface? = null
    private var handle: Long = 0
    private var bitmap: Bitmap? = null
    private var width = 0
    private var height = 0
    @Volatile private var generation = 0
    private var lastBlank = false

    fun attach(registry: TextureRegistry) {
        this.registry = registry
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadTexture" -> {
                val script = call.argument<ByteArray>("script")
                if (script == null) {
                    result.error("ASS_RENDER_FAILED", "Missing ASS script", null)
                    return
                }
                val w = (call.argument<Int>("width") ?: 1280).coerceIn(1, 3840)
                val h = (call.argument<Int>("height") ?: 720).coerceIn(1, 2160)
                // TextureRegistry operations are performed on the platform thread.
                val textures = registry
                if (textures == null) {
                    result.error("ASS_RENDER_FAILED", "Flutter texture registry unavailable", null)
                    return
                }
                val currentGeneration = ++generation
                worker.execute {
                    try {
                        releaseNative()
                        val nativeHandle = AssDirectBridge.nativeInit(w, h, 1.0f)
                        if (nativeHandle == 0L) throw IllegalStateException("libass initialization failed")
                        handle = nativeHandle
                        if (AssDirectBridge.nativeLoadScript(nativeHandle, script) != 0) {
                            throw IllegalArgumentException("Invalid ASS script")
                        }
                        width = w
                        height = h
                        bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                        lastBlank = false
                        main.post {
                            if (generation != currentGeneration) {
                                result.error("ASS_CANCELLED", "Subtitle load superseded", null)
                                return@post
                            }
                            try {
                                releaseTexture()
                                val texture = textures.createSurfaceTexture()
                                texture.surfaceTexture().setDefaultBufferSize(w, h)
                                entry = texture
                                surface = Surface(texture.surfaceTexture())
                                // Ensure an initially transparent texture.
                                drawFrame(null)
                                lastBlank = true
                                Log.i("ASSRENDER", "Native texture ready: ${w}x${h}, id=${texture.id()}")
                                result.success(texture.id())
                            } catch (e: Exception) {
                                result.error("ASS_RENDER_FAILED", e.toString(), null)
                            }
                        }
                    } catch (e: Exception) {
                        main.post { result.error("ASS_RENDER_FAILED", e.toString(), null) }
                    }
                }
            }
            "renderTexture" -> {
                val timeMs = (call.argument<Number>("timeMs") ?: 0).toLong()
                val currentGeneration = generation
                worker.execute {
                    try {
                        if (currentGeneration != generation || handle == 0L) {
                            main.post { result.success(false) }
                            return@execute
                        }
                        val target = bitmap
                        if (target == null) {
                            main.post { result.success(false) }
                            return@execute
                        }
                        val state = AssDirectBridge.nativeRenderState(handle, timeMs, target)
                        // state 2: static unchanged. state 0: blank, clear texture.
                        if (state == 1) {
                            drawFrame(target)
                            lastBlank = false
                        } else if (state == 0 && !lastBlank) {
                            drawFrame(null)
                            lastBlank = true
                        }
                        main.post { result.success(state != 0) }
                    } catch (e: Exception) {
                        main.post { result.error("ASS_RENDER_FAILED", e.toString(), null) }
                    }
                }
            }
            "disposeTexture" -> {
                ++generation
                worker.execute {
                    releaseNative()
                    main.post {
                        releaseTexture()
                        result.success(null)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun drawFrame(frame: Bitmap?) {
        val target = surface ?: return
        var canvas: Canvas? = null
        try {
            canvas = target.lockCanvas(null)
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
            if (frame != null) {
                canvas.drawBitmap(frame, null,
                    android.graphics.Rect(0, 0, width, height), null)
            }
        } finally {
            if (canvas != null) target.unlockCanvasAndPost(canvas)
        }
    }

    private fun releaseNative() {
        if (handle != 0L) {
            AssDirectBridge.nativeDestroy(handle)
            handle = 0
        }
        bitmap?.recycle()
        bitmap = null
    }

    private fun releaseTexture() {
        surface?.release()
        surface = null
        entry?.release()
        entry = null
    }
}
