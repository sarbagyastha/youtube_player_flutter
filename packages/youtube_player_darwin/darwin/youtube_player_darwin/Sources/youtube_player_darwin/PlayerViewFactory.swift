// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

#if os(iOS)
  import Flutter
  import UIKit
  typealias PlatformView = UIView
#elseif os(macOS)
  import FlutterMacOS
  import AppKit
  typealias PlatformView = NSView
#endif

/// Each platform view is a container that adopts the host's WKWebView.
/// Moving the widget creates a new container and the same WebView moves into
/// it, so playback never restarts.
@MainActor
final class PlayerViewFactory: NSObject, @preconcurrency FlutterPlatformViewFactory {
  private weak var plugin: YoutubePlayerDarwinPlugin?

  init(plugin: YoutubePlayerDarwinPlugin) {
    self.plugin = plugin
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  private func container(for args: Any?) -> PlatformView {
    let container = PlatformView(frame: .zero)
    #if os(iOS)
      container.backgroundColor = .clear
    #endif
    guard
      let handle = (args as? [String: Any])?["handle"] as? NSNumber,
      let host = plugin?.hosts[handle.int64Value]
    else { return container }

    let webView = host.webView
    webView.removeFromSuperview()
    webView.frame = container.bounds
    #if os(iOS)
      webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    #elseif os(macOS)
      webView.autoresizingMask = [.width, .height]
    #endif
    container.addSubview(webView)
    return container
  }

  #if os(iOS)
    func create(
      withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?
    ) -> FlutterPlatformView {
      ContainerPlatformView(container(for: args))
    }
  #elseif os(macOS)
    func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
      container(for: args)
    }
  #endif
}

#if os(iOS)
  @MainActor
  private final class ContainerPlatformView: NSObject, @preconcurrency FlutterPlatformView {
    private let container: UIView

    init(_ container: UIView) { self.container = container }

    func view() -> UIView { container }
  }
#endif
