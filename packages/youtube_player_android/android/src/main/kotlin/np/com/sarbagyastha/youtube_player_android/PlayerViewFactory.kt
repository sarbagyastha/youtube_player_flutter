// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

package np.com.sarbagyastha.youtube_player_android

import android.content.Context
import android.view.View
import android.view.ViewGroup
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** Shows an existing [PlayerHost]'s WebView. Re-parenting moves the same
 *  WebView, so the player never reloads when the widget moves. */
internal class PlayerViewFactory(
    private val hosts: Map<Long, PlayerHost>,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val handle = ((args as? Map<*, *>)?.get("handle") as? Number)?.toLong()
        val host = handle?.let(hosts::get)
            ?: return EmptyView(View(context))
        return HostView(host)
    }

    private class HostView(private val host: PlayerHost) : PlatformView {
        init {
            (host.webView.parent as? ViewGroup)?.removeView(host.webView)
            host.owner = this
        }

        override fun getView(): View = host.webView

        override fun dispose() {
            // Only detach if a newer platform view has not taken over.
            if (host.owner === this) {
                host.owner = null
                (host.webView.parent as? ViewGroup)?.removeView(host.webView)
            }
        }
    }

    private class EmptyView(private val view: View) : PlatformView {
        override fun getView(): View = view

        override fun dispose() = Unit
    }
}
