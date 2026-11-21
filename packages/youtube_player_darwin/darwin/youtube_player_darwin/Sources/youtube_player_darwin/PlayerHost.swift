// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import WebKit

#if os(iOS)
  import UIKit
  typealias PlatformColor = UIColor
#elseif os(macOS)
  import AppKit
  typealias PlatformColor = NSColor
#endif

/// One WKWebView running the player page. Lives until `destroy()`,
/// independent of the platform views that display it.
@MainActor
final class PlayerHost: NSObject {
  let webView: WKWebView
  private let handle: Int64
  private let baseURL: URL
  private weak var plugin: YoutubePlayerDarwinPlugin?
  private var fullscreenObservation: NSKeyValueObservation?
  private var destroyed = false

  init(handle: Int64, config: NativeHostConfig, baseURL: URL, plugin: YoutubePlayerDarwinPlugin) {
    self.handle = handle
    self.baseURL = baseURL
    self.plugin = plugin

    let configuration = WKWebViewConfiguration()
    configuration.mediaTypesRequiringUserActionForPlayback = []
    #if os(iOS)
      configuration.allowsInlineMediaPlayback = true
      configuration.allowsPictureInPictureMediaPlayback = true
    #endif
    if #available(iOS 15.4, macOS 12.3, *) {
      configuration.preferences.isElementFullscreenEnabled = true
    }
    if let frameScript = config.frameScript {
      // Runs in the cross-origin player iframe; the script itself bails out
      // anywhere but YouTube's embed page.
      configuration.userContentController.addUserScript(
        WKUserScript(source: frameScript, injectionTime: .atDocumentStart, forMainFrameOnly: false))
    }
    #if os(iOS)
      webView = PlayerWebView(frame: .zero, configuration: configuration)
    #elseif os(macOS)
      webView = WKWebView(frame: .zero, configuration: configuration)
    #endif
    super.init()

    configuration.userContentController.add(WeakMessageHandler(self), name: "ypBridge")
    webView.navigationDelegate = self
    webView.uiDelegate = self
    webView.customUserAgent = config.userAgent
    webView.allowsBackForwardNavigationGestures = false
    if #available(iOS 16.4, macOS 13.3, *) {
      webView.isInspectable = config.debuggable
    }
    #if os(iOS)
      webView.isOpaque = false
      webView.scrollView.isScrollEnabled = false
      webView.scrollView.bounces = false
      webView.scrollView.contentInsetAdjustmentBehavior = .never
    #elseif os(macOS)
      webView.setValue(false, forKey: "drawsBackground")
    #endif
    setBackgroundColor(config.backgroundColor ?? 0)
    observeFullscreen()
  }

  func load(_ html: String) {
    webView.loadHTMLString(html, baseURL: baseURL)
  }

  func send(_ json: String) {
    guard !destroyed else { return }
    webView.callAsyncJavaScript(
      "window.__yp && window.__yp.recv(json)",
      arguments: ["json": json],
      in: nil,
      in: .page,
      completionHandler: nil
    )
  }

  func setBackgroundColor(_ argb: Int64) {
    let color = PlatformColor(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255
    )
    #if os(iOS)
      webView.backgroundColor = color
      webView.scrollView.backgroundColor = color
    #elseif os(macOS)
      webView.underPageBackgroundColor = color
    #endif
  }

  /// Leaves element fullscreen and native video presentations.
  func exitFullscreen() {
    webView.evaluateJavaScript(
      "document.fullscreenElement && document.exitFullscreen()",
      completionHandler: nil)
    webView.closeAllMediaPresentations {}
  }

  func destroy() {
    guard !destroyed else { return }
    destroyed = true
    fullscreenObservation = nil
    webView.configuration.userContentController.removeScriptMessageHandler(forName: "ypBridge")
    webView.configuration.userContentController.removeAllUserScripts()
    webView.navigationDelegate = nil
    webView.uiDelegate = nil
    webView.stopLoading()
    webView.loadHTMLString("", baseURL: nil)
    webView.removeFromSuperview()
  }

  private func observeFullscreen() {
    guard #available(iOS 16.0, macOS 13.0, *) else { return }
    fullscreenObservation = webView.observe(\.fullscreenState, options: [.new]) {
      [weak self] webView, _ in
      MainActor.assumeIsolated {
        guard let self else { return }
        switch webView.fullscreenState {
        case .inFullscreen: self.plugin?.onFullscreenChanged(self.handle, true)
        case .notInFullscreen: self.plugin?.onFullscreenChanged(self.handle, false)
        default: break
        }
      }
    }
  }

  fileprivate func receive(_ body: Any) {
    guard !destroyed, let json = body as? String else { return }
    plugin?.onMessage(handle, json)
  }
}

#if os(iOS)
  /// Flutter owns the layout, safe areas included, so the page lays out edge
  /// to edge in whatever frame it gets. Otherwise WebKit offsets the content
  /// by the notch inset (e.g. landscape fullscreen: extra gap on one side, the
  /// other side cropped).
  private final class PlayerWebView: WKWebView {
    override var safeAreaInsets: UIEdgeInsets { .zero }
  }
#endif

// MARK: - Navigation

extension PlayerHost: WKNavigationDelegate, WKUIDelegate {
  func webView(
    _ webView: WKWebView,
    decidePolicyFor action: WKNavigationAction,
    decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
  ) {
    guard let url = action.request.url else { return decisionHandler(.cancel) }
    // The player's own iframe navigates freely.
    if let frame = action.targetFrame, !frame.isMainFrame { return decisionHandler(.allow) }
    // The initial page load (and its about: documents) stay.
    if action.targetFrame != nil, url == baseURL || url.scheme == "about" {
      return decisionHandler(.allow)
    }
    // Everything else leaves the player: hand it to Dart.
    plugin?.onNavigation(handle, url.absoluteString)
    decisionHandler(.cancel)
  }

  func webView(
    _ webView: WKWebView,
    createWebViewWith configuration: WKWebViewConfiguration,
    for action: WKNavigationAction,
    windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    if let url = action.request.url { plugin?.onNavigation(handle, url.absoluteString) }
    return nil
  }

  func webView(
    _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    reportLoadError(error)
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    reportLoadError(error)
  }

  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    plugin?.onLoadError(
      handle, NativeLoadError(code: -1, message: "WebContent process terminated", url: nil))
  }

  private func reportLoadError(_ error: Error) {
    let nsError = error as NSError
    // Cancelled loads and policy interruptions are our own doing.
    if nsError.code == NSURLErrorCancelled || (nsError.domain == "WebKitErrorDomain" && nsError.code == 102) {
      return
    }
    plugin?.onLoadError(
      handle,
      NativeLoadError(
        code: Int64(nsError.code),
        message: nsError.localizedDescription,
        url: (nsError.userInfo[NSURLErrorFailingURLStringErrorKey] as? String)
      ))
  }
}

// MARK: - Script bridge

/// Breaks the WKUserContentController -> handler retain cycle.
private final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
  private weak var host: PlayerHost?

  init(_ host: PlayerHost) { self.host = host }

  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    MainActor.assumeIsolated { host?.receive(message.body) }
  }
}
