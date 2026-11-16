// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

package np.com.sarbagyastha.youtube_player_android

import android.app.Activity
import android.content.Context
import android.content.MutableContextWrapper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import np.com.sarbagyastha.youtube_player_android.pigeon.FlutterError
import np.com.sarbagyastha.youtube_player_android.pigeon.NativeHostConfig
import np.com.sarbagyastha.youtube_player_android.pigeon.NativeHostInfo
import np.com.sarbagyastha.youtube_player_android.pigeon.NativeLoadError
import np.com.sarbagyastha.youtube_player_android.pigeon.YoutubeFlutterApi
import np.com.sarbagyastha.youtube_player_android.pigeon.YoutubeHostApi

internal const val VIEW_TYPE = "np.com.sarbagyastha.youtube_player/webview"

/** Hosts YouTube IFrame API players in plain [android.webkit.WebView]s. */
class YoutubePlayerAndroidPlugin : FlutterPlugin, ActivityAware, YoutubeHostApi {
    private var appContext: Context? = null
    private var flutterApi: YoutubeFlutterApi? = null
    private var scope: CoroutineScope? = null
    private val hosts = mutableMapOf<Long, PlayerHost>()
    private var nextHandle = 0L

    /** WebViews are created with this wrapper so they can use the Activity
     *  (needed for fullscreen custom views) without leaking it. */
    private var webViewContext: MutableContextWrapper? = null

    internal var activity: Activity? = null
        private set

    // region FlutterPlugin

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        webViewContext = MutableContextWrapper(binding.applicationContext)
        flutterApi = YoutubeFlutterApi(binding.binaryMessenger)
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        YoutubeHostApi.setUp(binding.binaryMessenger, this)
        binding.platformViewRegistry.registerViewFactory(VIEW_TYPE, PlayerViewFactory(hosts))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        YoutubeHostApi.setUp(binding.binaryMessenger, null)
        hosts.values.forEach(PlayerHost::destroy)
        hosts.clear()
        scope?.cancel()
        scope = null
        flutterApi = null
        appContext = null
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
        appContext?.let { webViewContext?.baseContext = it }
    }

    // endregion

    // region YoutubeHostApi

    override fun create(config: NativeHostConfig): NativeHostInfo {
        val context = webViewContext ?: throw FlutterError("detached", "Plugin is not attached")
        val appId = (config.appId ?: context.packageName).lowercase()
        val handle = nextHandle++
        hosts[handle] = PlayerHost(handle, context, config, "https://$appId", this)
        return NativeHostInfo(handle, "https://$appId")
    }

    override fun load(handle: Long, html: String) = host(handle).load(html)

    override fun send(handle: Long, json: String) = host(handle).send(json)

    override fun setBackgroundColor(handle: Long, argb: Long) =
        host(handle).setBackgroundColor(argb.toInt())

    override fun exitFullscreen(handle: Long) {
        hosts[handle]?.exitFullscreen()
    }

    override fun dispose(handle: Long) {
        hosts.remove(handle)?.destroy()
    }

    private fun host(handle: Long) =
        hosts[handle] ?: throw FlutterError("no-host", "No player with handle $handle")

    // endregion

    // region Host -> Dart (always on the main thread, in order)

    private fun toDart(block: suspend YoutubeFlutterApi.() -> Unit) {
        val api = flutterApi ?: return
        scope?.launch {
            try {
                api.block()
            } catch (_: FlutterError) {
                // Dart side not listening (e.g. during hot restart); drop.
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
