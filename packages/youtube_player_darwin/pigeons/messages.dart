// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// Regenerate with: dart run pigeon --input pigeons/messages.dart
//
// Uses Pigeon Native Interop (FFI): calls are direct, no platform channels.
// Requires macOS with Xcode command line tools.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'youtube_player_darwin',
    // FFIgen compiles the Swift bridge directly; paths resolve from here.
    appDirectory: './',
    dartOut: 'lib/src/messages.g.dart',
    swiftOut: 'darwin/youtube_player_darwin/Sources/youtube_player_darwin/Messages.g.swift',
    swiftOptions: SwiftOptions(
      useFfi: true,
      ffiModuleName: 'youtube_player_darwin',
    ),
    copyrightHeader: 'pigeons/copyright.txt',
  ),
)
/// Configuration for a new player WebView.
class NativeHostConfig {
  NativeHostConfig({
    required this.debuggable,
    this.appId,
    this.userAgent,
    this.backgroundColor,
    this.frameScript,
  });

  /// Client identity; defaults to the bundle identifier.
  String? appId;
  String? userAgent;
  bool debuggable;

  /// ARGB background color.
  int? backgroundColor;

  /// Injected at document start into the YouTube player iframe, when set.
  String? frameScript;
}

/// Result of [YoutubeHostApi.create].
class NativeHostInfo {
  NativeHostInfo({
    required this.handle,
    required this.origin,
    required this.frameScripting,
  });

  int handle;

  /// `https://<appId>`; the page is loaded under this origin.
  String origin;

  /// Whether the frame script was injected.
  bool frameScripting;
}

/// Main-frame load failure.
class NativeLoadError {
  NativeLoadError({required this.code, required this.message, this.url});

  int code;
  String message;
  String? url;
}

/// Dart -> iOS / macOS. All calls are synchronous and run on the main thread.
@HostApi()
abstract class YoutubeHostApi {
  /// Creates a WebView, loads [html] under the host's origin and returns its
  /// handle and origin.
  NativeHostInfo create(NativeHostConfig config, String html);

  /// Delivers [json] to `window.__yp.recv`.
  void send(int handle, String json);

  void setBackgroundColor(int handle, int argb);

  void exitFullscreen(int handle);

  void dispose(int handle);

  /// Opens [url] in the app that handles it, or the default browser.
  /// Returns whether the request was accepted.
  bool openExternal(String url);

  /// Destroys every player, e.g. those orphaned by a hot restart.
  void reset();
}

/// iOS / macOS -> Dart. Always invoked on the main thread, on a fresh loop
/// turn.
@FlutterApi()
abstract class YoutubeFlutterApi {
  void onMessage(int handle, String json);

  void onNavigation(int handle, String url);

  void onLoadError(int handle, NativeLoadError error);

  void onFullscreenChanged(int handle, bool isFullscreen);
}
