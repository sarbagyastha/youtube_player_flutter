// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif
import WebKit

let viewType = "np.com.sarbagyastha.youtube_player/webview"

/// Hosts YouTube IFrame API players in plain WKWebViews.
///
/// Dart talks to this class through Pigeon Native Interop (FFI): host calls
/// are direct, synchronous calls on the main thread, and events go back
/// through the Dart-implemented `YoutubeFlutterApi`.
@MainActor
public final class YoutubePlayerDarwinPlugin: NSObject, @preconcurrency FlutterPlugin, @preconcurrency YoutubeHostApi {
  private let registrar: FlutterPluginRegistrar
  private(set) var hosts: [Int64: PlayerHost] = [:]
  private var nextHandle: Int64 = 0

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  // Flutter registers plugins on the main thread.
  public nonisolated static func register(with registrar: FlutterPluginRegistrar) {
    // The registrar is only ever touched on the main thread.
    nonisolated(unsafe) let registrar = registrar
    MainActor.assumeIsolated {
      let plugin = YoutubePlayerDarwinPlugin(registrar: registrar)
      YoutubeHostApiSetup.register(api: plugin, registrar: registrar)
      registrar.register(PlayerViewFactory(plugin: plugin), withId: viewType)
      // Required for `detachFromEngine` on iOS. macOS has no detach callback.
      registrar.publish(plugin)
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    YoutubeHostApiSetup.unregister(api: self, registrar: registrar)
    try? reset()
  }

  // MARK: YoutubeHostApi (main thread, synchronous)

  func create(config: NativeHostConfig, html: String) throws -> NativeHostInfo {
    let appId = (config.appId ?? Bundle.main.bundleIdentifier ?? "app").lowercased()
    guard let baseURL = URL(string: "https://\(appId)/") else {
      throw PigeonError(code: "bad-app-id", message: "Invalid app id \(appId)", details: nil)
    }
    let handle = nextHandle
    nextHandle += 1
    let host = PlayerHost(handle: handle, config: config, baseURL: baseURL, plugin: self)
    hosts[handle] = host
    host.load(html)
    return NativeHostInfo(
      handle: handle, origin: "https://\(appId)", frameScripting: config.frameScript != nil)
  }

  func send(handle: Int64, json: String) throws { try host(handle).send(json) }

  func setBackgroundColor(handle: Int64, argb: Int64) throws {
    try host(handle).setBackgroundColor(argb)
  }

  func exitFullscreen(handle: Int64) throws { hosts[handle]?.exitFullscreen() }

  func dispose(handle: Int64) throws { hosts.removeValue(forKey: handle)?.destroy() }

  func openExternal(url: String) throws -> Bool {
    guard let url = URL(string: url) else { return false }
    #if os(iOS)
      // Opens the handling app (e.g. YouTube) via universal links, or Safari.
      // No `canOpenURL`: it needs schemes declared in Info.plist.
      UIApplication.shared.open(url)
      return true
    #elseif os(macOS)
      return NSWorkspace.shared.open(url)
    #endif
  }

  func reset() throws {
    let all = hosts.values
    hosts.removeAll()
    all.forEach { $0.destroy() }
  }

  private func host(_ handle: Int64) throws -> PlayerHost {
    guard let host = hosts[handle] else {
      throw PigeonError(code: "no-host", message: "No player with handle \(handle)", details: nil)
    }
    return host
  }

  // MARK: Host -> Dart

  /// Always delivered on a later main-queue turn, so a callback never
  /// re-enters Dart in the middle of a synchronous host call.
  private func toDart(_ call: @escaping @MainActor (YoutubeFlutterApi) throws -> Void) {
    let registrar = registrar
    nonisolated(unsafe) let unsafeRegistrar = registrar
    DispatchQueue.main.async {
      MainActor.assumeIsolated {
        guard let api = YoutubeFlutterApiRegistrar.getInstance(registrar: unsafeRegistrar) else { return }
        // Dart side gone (e.g. during hot restart); drop.
        try? call(api)
      }
    }
  }

  func onMessage(_ handle: Int64, _ json: String) {
    toDart { try $0.onMessage(handle: handle, json: json) }
  }

  func onNavigation(_ handle: Int64, _ url: String) {
    toDart { try $0.onNavigation(handle: handle, url: url) }
  }

  func onLoadError(_ handle: Int64, _ error: NativeLoadError) {
    toDart { try $0.onLoadError(handle: handle, error: error) }
  }

  func onFullscreenChanged(_ handle: Int64, _ isFullscreen: Bool) {
    toDart { try $0.onFullscreenChanged(handle: handle, isFullscreen: isFullscreen) }
  }
}
