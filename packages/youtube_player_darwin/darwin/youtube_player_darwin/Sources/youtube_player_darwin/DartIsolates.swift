// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import Foundation

/// Tracks engines whose Dart isolate has shut down (hot restart) and whose new
/// isolate has not attached yet.
///
/// The `YoutubeFlutterApi` registered by an isolate is implemented by
/// isolate-local Dart callbacks; calling it after that isolate is gone aborts
/// the process. Pigeon's registry outlives the isolate, so the plugin checks
/// here before every callback.
enum DartIsolates {
  static let didShutDown = Notification.Name("np.com.sarbagyastha.youtube_player.isolateShutDown")

  private static let lock = NSLock()
  nonisolated(unsafe) private static var detached = Set<Int64>()

  static func markDetached(_ engine: Int64) {
    lock.lock()
    defer { lock.unlock() }
    detached.insert(engine)
  }

  static func markAttached(_ engine: Int64) {
    lock.lock()
    defer { lock.unlock() }
    detached.remove(engine)
  }

  static func isDetached(_ engine: Int64) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return detached.contains(engine)
  }
}

/// Dart attaches this as a `NativeFinalizer` with the engine id as its token.
/// Native finalizers run when the isolate group shuts down, which is when a
/// hot restart discards the old isolate.
@_cdecl("youtube_player_darwin_isolate_shutdown")
public func youtubePlayerDarwinIsolateShutdown(_ token: UnsafeMutableRawPointer?) {
  let engine = Int64(Int(bitPattern: token))
  // Synchronous, so no queued callback can reach the dead isolate.
  DartIsolates.markDetached(engine)
  DispatchQueue.main.async {
    NotificationCenter.default.post(
      name: DartIsolates.didShutDown, object: nil, userInfo: ["engine": engine])
  }
}
