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
@MainActor
public final class YoutubePlayerDarwinPlugin: NSObject, @preconcurrency FlutterPlugin, @preconcurrency YoutubeHostApi {
  private let flutterApi: YoutubeFlutterApi
  private(set) var hosts: [Int64: PlayerHost] = [:]
  private var nextHandle: Int64 = 0

  init(messenger: FlutterBinaryMessenger) {
    flutterApi = YoutubeFlutterApi(binaryMessenger: messenger)
  }

  // Flutter registers plugins on the main thread.
  public nonisolated static func register(with registrar: FlutterPluginRegistrar) {
    // The registrar is only ever touched on the main thread.
    nonisolated(unsafe) let registrar = registrar
    MainActor.assumeIsolated {
      #if os(iOS)
        let messenger = registrar.messenger()
      #else
        let messenger = registrar.messenger
      #endif
      let plugin = YoutubePlayerDarwinPlugin(messenger: messenger)
      YoutubeHostApiSetup.setUp(binaryMessenger: messenger, api: plugin)
      registrar.register(PlayerViewFactory(plugin: plugin), withId: viewType)
      registrar.publish(plugin)
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    #if os(iOS)
      let messenger = registrar.messenger()
    #else
      let messenger = registrar.messenger
    #endif
    YoutubeHostApiSetup.setUp(binaryMessenger: messenger, api: nil)
    hosts.values.forEach { $0.destroy() }
    hosts.removeAll()
  }

  // MARK: YoutubeHostApi

  func create(config: NativeHostConfig) throws -> NativeHostInfo {
    let appId = (config.appId ?? Bundle.main.bundleIdentifier ?? "app").lowercased()
    guard let baseURL = URL(string: "https://\(appId)/") else {
      throw PigeonError(code: "bad-app-id", message: "Invalid app id \(appId)", details: nil)
    }
    let handle = nextHandle
    nextHandle += 1
    hosts[handle] = PlayerHost(handle: handle, config: config, baseURL: baseURL, plugin: self)
    return NativeHostInfo(handle: handle, origin: "https://\(appId)")
  }

  func load(handle: Int64, html: String) throws { try host(handle).load(html) }

  func send(handle: Int64, json: String) throws { try host(handle).send(json) }

  func setBackgroundColor(handle: Int64, argb: Int64) throws {
    try host(handle).setBackgroundColor(argb)
  }

  func exitFullscreen(handle: Int64) throws { hosts[handle]?.exitFullscreen() }

  func dispose(handle: Int64) throws { hosts.removeValue(forKey: handle)?.destroy() }

  private func host(_ handle: Int64) throws -> PlayerHost {
    guard let host = hosts[handle] else {
      throw PigeonError(code: "no-host", message: "No player with handle \(handle)", details: nil)
    }
    return host
  }

  // MARK: Host -> Dart

  private func toDart(_ call: @escaping @MainActor (YoutubeFlutterApi) async throws -> Void) {
    let api = flutterApi
    Task { @MainActor in try? await call(api) }
  }

  func onMessage(_ handle: Int64, _ json: String) {
    toDart { try await $0.onMessage(handle: handle, json: json) }
  }

  func onNavigation(_ handle: Int64, _ url: String) {
    toDart { try await $0.onNavigation(handle: handle, url: url) }
  }

  func onLoadError(_ handle: Int64, _ error: NativeLoadError) {
    toDart { try await $0.onLoadError(handle: handle, error: error) }
  }

  func onFullscreenChanged(_ handle: Int64, _ isFullscreen: Bool) {
    toDart { try await $0.onFullscreenChanged(handle: handle, isFullscreen: isFullscreen) }
  }
}
