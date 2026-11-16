// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

package np.com.sarbagyastha.youtube_player_android

import android.app.Activity
import android.content.Context
import android.content.MutableContextWrapper
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import np.com.sarbagyastha.youtube_player_android.pigeon.FlutterError
import np.com.sarbagyastha.youtube_player_android.pigeon.NativeHostConfig
import np.com.sarbagyastha.youtube_player_android.pigeon.NativeHostInfo
import np.com.sarbagyastha.youtube_player_android.pigeon.NativeLoadError
import np.com.sarbagyastha.youtube_player_android.pigeon.YoutubeFlutterApi
import np.com.sarbagyastha.youtube_player_android.pigeon.YoutubeFlutterApiRegistrar
import np.com.sarbagyastha.youtube_player_android.pigeon.YoutubeHostApi
import np.com.sarbagyastha.youtube_player_android.pigeon.YoutubeHostApiRegistrar

internal const val VIEW_TYPE = "np.com.sarbagyastha.youtube_player/webview"

/** Hosts YouTube IFrame API players in plain [android.webkit.WebView]s.
 *
 *  Dart talks to this class through Pigeon Native Interop (JNI): host calls
 *  are direct, synchronous calls on the main thread, and events go back
 *  through the Dart-implemented [YoutubeFlutterApi]. */
class YoutubePlayerAndroidPlugin : FlutterPlugin, ActivityAware, YoutubeHostApi {
    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val hosts = mutableMapOf<Long, PlayerHost>()
    private var nextHandle = 0L

    /** WebViews are created with this wrapper so they can use the Activity
     *  (needed for fullscreen custom views) without leaking it. */
    private var webViewContext: MutableContextWrapper? = null

    internal var activity: Activity? = null
        private set

    // region FlutterPlugin

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.binding = binding
        webViewContext = MutableContextWrapper(binding.applicationContext)
        YoutubeHostApiRegistrar().register(this, binding)
        binding.platformViewRegistry.registerViewFactory(VIEW_TYPE, PlayerViewFactory(hosts))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        YoutubeHostApiRegistrar().unregister(this, binding)
        reset()
        mainHandler.removeCallbacksAndMessages(null)
        this.binding = null
        webViewContext = null
    }

    // endregion

    // region ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        webViewContext?.baseContext = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() = detachActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() = detachActivity()

    private fun detachActivity() {
        hosts.values.forEach { it.exitFullscreen() }
        activity = null
        binding?.applicationContext?.let { webViewContext?.baseContext = it }
    }

    // endregion

    // region YoutubeHostApi (main thread, synchronous)

    override fun create(config: NativeHostConfig, html: String): NativeHostInfo {
        val context = webViewContext ?: throw FlutterError("detached", "Plugin is not attached")
        val appId = (config.appId ?: context.packageName).lowercase()
        val origin = "https://$appId"
        val handle = nextHandle++
        hosts[handle] = PlayerHost(handle, context, config, origin, this).also { it.load(html) }
        return NativeHostInfo(handle, origin)
    }

    override fun send(handle: Long, json: String) = host(handle).send(json)

    override fun setBackgroundColor(handle: Long, argb: Long) =
        host(handle).setBackgroundColor(argb.toInt())

    override fun exitFullscreen(handle: Long) {
        hosts[handle]?.exitFullscreen()
    }

    override fun dispose(handle: Long) {
        hosts.remove(handle)?.destroy()
    }

    override fun reset() {
        val all = hosts.values.toList()
        hosts.clear()
        all.forEach(PlayerHost::destroy)
    }

    private fun host(handle: Long) =
        hosts[handle] ?: throw FlutterError("no-host", "No player with handle $handle")

    // endregion

    // region Host -> Dart

    /** Always delivered on a later main-loop turn: never re-enters Dart in the
     *  middle of a synchronous host call, and hops off the JavaBridge thread. */
    private fun toDart(block: YoutubeFlutterApi.() -> Unit) {
        mainHandler.post {
            val binding = binding ?: return@post
            val api = YoutubeFlutterApiRegistrar().getInstance(binding) ?: return@post
            try {
                api.block()
            } catch (_: FlutterError) {
                // Dart side gone (e.g. during hot restart); drop.
            }
        }
    }

    internal fun onMessage(handle: Long, json: String) = toDart { onMessage(handle, json) }

    internal fun onNavigation(handle: Long, url: String) = toDart { onNavigation(handle, url) }

    internal fun onLoadError(handle: Long, error: NativeLoadError) =
        toDart { onLoadError(handle, error) }

    internal fun onFullscreenChanged(handle: Long, isFullscreen: Boolean) =
        toDart { onFullscreenChanged(handle, isFullscreen) }

    // endregion
}
