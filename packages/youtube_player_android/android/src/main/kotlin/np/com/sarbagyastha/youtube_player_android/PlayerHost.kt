// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

package np.com.sarbagyastha.youtube_player_android

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.ActivityInfo
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Build
import android.os.Message
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.RenderProcessGoneDetail
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.webkit.ScriptHandler
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import np.com.sarbagyastha.youtube_player_android.pigeon.NativeFullscreenOrientation
import np.com.sarbagyastha.youtube_player_android.pigeon.NativeHostConfig
import np.com.sarbagyastha.youtube_player_android.pigeon.NativeLoadError
import org.json.JSONObject

/** One WebView running the player page. Lives until [destroy], independent
 *  of the platform views that display it. */
private const val SINK_TIMEOUT_MS = 10_000L

/** Origins the frame script runs in: the player iframe's hosts. */
private val FRAME_ORIGINS = setOf("https://www.youtube.com", "https://www.youtube-nocookie.com")

internal class PlayerHost(
    private val handle: Long,
    context: Context,
    private val config: NativeHostConfig,
    private val baseUrl: String,
    private val plugin: YoutubePlayerAndroidPlugin,
) {
    val webView: WebView = WebView(context)

    /** The platform view currently showing [webView], if any. */
    var owner: Any? = null

    private var fullscreen: Fullscreen? = null
    private var destroyed = false

    /** Throwaway WebViews that catch `target=_blank` URLs. */
    private val sinks = mutableSetOf<WebView>()

    /** The injected frame script, if [NativeHostConfig.frameScript] was set
     *  and the WebView supports document-start scripts. */
    private var frameScript: ScriptHandler? = null

    /** Whether the frame script is installed. */
    val frameScripting: Boolean
        get() = frameScript != null

    init {
        if (config.debuggable) WebView.setWebContentsDebuggingEnabled(true)
        configure()
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun configure() = with(webView) {
        settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            mediaPlaybackRequiresUserGesture = false
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
            setSupportMultipleWindows(true)
            javaScriptCanOpenWindowsAutomatically = false
            config.userAgent?.let { userAgentString = it }
        }
        overScrollMode = View.OVER_SCROLL_NEVER
        isVerticalScrollBarEnabled = false
        isHorizontalScrollBarEnabled = false
        isHapticFeedbackEnabled = false
        setBackgroundColor(config.backgroundColor?.toInt() ?: Color.TRANSPARENT)
        addJavascriptInterface(Bridge(), "ypBridge")
        val script = config.frameScript
        if (script != null && WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)) {
            frameScript = WebViewCompat.addDocumentStartJavaScript(this, script, FRAME_ORIGINS)
        }
        webViewClient = Client()
        webChromeClient = Chrome()
    }

    fun load(html: String) {
        webView.loadDataWithBaseURL("$baseUrl/", html, "text/html", "utf-8", null)
    }

    fun send(json: String) {
        if (destroyed) return
        webView.evaluateJavascript("window.__yp&&__yp.recv(${JSONObject.quote(json)})", null)
    }

    fun setBackgroundColor(argb: Int) = webView.setBackgroundColor(argb)

    fun exitFullscreen() = fullscreen?.exit(notifyWebView = true)

    fun destroy() {
        if (destroyed) return
        destroyed = true
        exitFullscreen()
        owner = null
        (webView.parent as? ViewGroup)?.removeView(webView)
        sinks.forEach(WebView::destroy)
        sinks.clear()
        frameScript?.remove()
        frameScript = null
        webView.removeJavascriptInterface("ypBridge")
        webView.stopLoading()
        webView.destroy()
    }

    /** Called by the JavaBridge thread; hop to main via the plugin. */
    private inner class Bridge {
        @JavascriptInterface
        fun postMessage(json: String) {
            if (!destroyed) plugin.onMessage(handle, json)
        }
    }

    private inner class Client : WebViewClient() {
        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            if (!request.isForMainFrame) return false
            plugin.onNavigation(handle, request.url.toString())
            return true
        }

        override fun onReceivedError(
            view: WebView,
            request: WebResourceRequest,
            error: WebResourceError,
        ) {
            if (!request.isForMainFrame) return
            plugin.onLoadError(
                handle,
                NativeLoadError(
                    error.errorCode.toLong(),
                    error.description.toString(),
                    request.url.toString(),
                ),
            )
        }

        override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean {
            plugin.onLoadError(
                handle,
                NativeLoadError(-1, "WebView renderer gone (crashed=${detail.didCrash()})", null),
            )
            destroy()
            return true
        }
    }

    private inner class Chrome : WebChromeClient() {
        override fun onShowCustomView(view: View, callback: CustomViewCallback) {
            if (fullscreen != null) return callback.onCustomViewHidden()
            val activity = plugin.activity ?: return callback.onCustomViewHidden()
            fullscreen = Fullscreen(activity, view, callback)
        }

        override fun onHideCustomView() {
            fullscreen?.exit(notifyWebView = false)
        }

        /** `target=_blank` links: capture the URL and forward it. */
        override fun onCreateWindow(
            view: WebView,
            isDialog: Boolean,
            isUserGesture: Boolean,
            resultMsg: Message,
        ): Boolean {
            val sink = WebView(view.context)
            sinks += sink
            val release = Runnable {
                if (sinks.remove(sink)) sink.destroy()
            }
            sink.webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(
                    v: WebView,
                    request: WebResourceRequest,
                ): Boolean {
                    plugin.onNavigation(handle, request.url.toString())
                    v.post(release)
                    return true
                }
            }
            // Popups that never navigate (e.g. blocked or script-only).
            view.postDelayed(release, SINK_TIMEOUT_MS)
            (resultMsg.obj as WebView.WebViewTransport).webView = sink
            resultMsg.sendToTarget()
            return true
        }

        /** Avoids the grey play-button poster flashing before the player. */
        override fun getDefaultVideoPoster(): Bitmap =
            Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
    }

    /** System fullscreen: the WebView's custom view on top of the Activity. */
    private inner class Fullscreen(
        private val activity: android.app.Activity,
        private val view: View,
        private val callback: WebChromeClient.CustomViewCallback,
    ) {
        private val decor = activity.window.decorView as FrameLayout
        private val insets = WindowCompat.getInsetsController(activity.window, decor)
        private val savedOrientation = activity.requestedOrientation
        private var backCallback: Any? = null

        init {
            view.setBackgroundColor(Color.BLACK)
            decor.addView(
                view,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                ),
            )
            insets.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            insets.hide(WindowInsetsCompat.Type.systemBars())
            when (config.fullscreenOrientation) {
                NativeFullscreenOrientation.LANDSCAPE ->
                    activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                NativeFullscreenOrientation.AUTO ->
                    activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_FULL_SENSOR
                NativeFullscreenOrientation.UNCHANGED -> Unit
            }
            registerBack()
            plugin.onFullscreenChanged(handle, true)
        }

        private fun registerBack() {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val cb = OnBackInvokedCallback { exit(notifyWebView = true) }
                activity.onBackInvokedDispatcher.registerOnBackInvokedCallback(
                    OnBackInvokedDispatcher.PRIORITY_OVERLAY,
                    cb,
                )
                backCallback = cb
            }
            // Pre-33 (and as a fallback): intercept the back key on the view.
            view.isFocusableInTouchMode = true
            view.requestFocus()
            view.setOnKeyListener { _, keyCode, event ->
                if (keyCode == KeyEvent.KEYCODE_BACK && event.action == KeyEvent.ACTION_UP) {
                    exit(notifyWebView = true)
                    true
                } else {
                    keyCode == KeyEvent.KEYCODE_BACK
                }
            }
        }

        fun exit(notifyWebView: Boolean) {
            if (fullscreen !== this) return
            fullscreen = null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                (backCallback as? OnBackInvokedCallback)?.let {
                    activity.onBackInvokedDispatcher.unregisterOnBackInvokedCallback(it)
                }
            }
            view.setOnKeyListener(null)
            decor.removeView(view)
            insets.show(WindowInsetsCompat.Type.systemBars())
            activity.requestedOrientation = savedOrientation
            if (notifyWebView) callback.onCustomViewHidden()
            plugin.onFullscreenChanged(handle, false)
        }
    }
}
