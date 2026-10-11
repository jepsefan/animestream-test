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
    private var perfFrames = 0
    private var perfNativeTotalNs = 0L
    private var perfCanvasTotalNs = 0L
    private var perfNativeMaxNs = 0L
    private var perfCanvasMaxNs = 0L
    private var perfWindowStartNs = 0L

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
                        perfFrames = 0
                        perfWindowStartNs = System.nanoTime()
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
                        val nativeStart = System.nanoTime()
                        val hasContent = AssDirectBridge.nativeRender(handle, timeMs, target)
                        val nativeNs = System.nanoTime() - nativeStart
                        val canvasStart = System.nanoTime()
                        // nativeRender is Boolean in the current assrender AAR.
                        // Redraw active subtitles every poll; this also preserves ASS animations.
                        if (hasContent) {
                            drawFrame(target)
                            lastBlank = false
                        } else if (!lastBlank) {
                            drawFrame(null)
                            lastBlank = true
                        }
                        val canvasNs = System.nanoTime() - canvasStart
                        perfFrames++
                        perfNativeTotalNs += nativeNs
                        perfCanvasTotalNs += canvasNs
                        if (nativeNs > perfNativeMaxNs) perfNativeMaxNs = nativeNs
                        if (canvasNs > perfCanvasMaxNs) perfCanvasMaxNs = canvasNs
                        val nowNs = System.nanoTime()
                        if (perfWindowStartNs == 0L) perfWindowStartNs = nowNs
                        val windowNs = nowNs - perfWindowStartNs
                        if (windowNs >= 5_000_000_000L && perfFrames > 0) {
                            Log.i("ASSRENDER", "[PERF_NATIVE] fps=%.1f nativeAvgMs=%.2f nativeMaxMs=%.2f canvasAvgMs=%.2f canvasMaxMs=%.2f playerMs=%d".format(
                                perfFrames * 1_000_000_000.0 / windowNs,
                                perfNativeTotalNs / perfFrames / 1_000_000.0,
                                perfNativeMaxNs / 1_000_000.0,
                                perfCanvasTotalNs / perfFrames / 1_000_000.0,
                                perfCanvasMaxNs / 1_000_000.0, timeMs))
                            perfFrames = 0
                            perfNativeTotalNs = 0L
                            perfCanvasTotalNs = 0L
                            perfNativeMaxNs = 0L
                            perfCanvasMaxNs = 0L
                            perfWindowStartNs = nowNs
                        }
                        main.post { result.success(hasContent) }
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
