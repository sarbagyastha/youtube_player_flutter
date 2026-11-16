// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// Regenerate with: dart run pigeon --input pigeons/messages.dart

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'youtube_player_darwin',
    dartOut: 'lib/src/messages.g.dart',
    swiftOut: 'darwin/youtube_player_darwin/Sources/youtube_player_darwin/Messages.g.swift',
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
  });

  /// Client identity; defaults to the bundle identifier.
  String? appId;
  String? userAgent;
  bool debuggable;

  /// ARGB background color.
  int? backgroundColor;
}

/// Result of [YoutubeHostApi.create].
class NativeHostInfo {
  NativeHostInfo({required this.handle, required this.origin});

  int handle;

  /// `https://<appId>`; the page is loaded under this origin.
  String origin;
}

/// Main-frame load failure.
class NativeLoadError {
  NativeLoadError({required this.code, required this.message, this.url});

  int code;
  String message;
  String? url;
}

/// Dart -> iOS / macOS.
@HostApi()
abstract class YoutubeHostApi {
  /// Creates a WebView and returns its handle and origin.
  NativeHostInfo create(NativeHostConfig config);

  /// Loads the player page under the host's origin.
  void load(int handle, String html);

  /// Delivers [json] to `window.__yp.recv`.
  void send(int handle, String json);

  void setBackgroundColor(int handle, int argb);

  void exitFullscreen(int handle);

  void dispose(int handle);
}

/// iOS / macOS -> Dart.
@FlutterApi()
abstract class YoutubeFlutterApi {
  void onMessage(int handle, String json);

  void onNavigation(int handle, String url);

  void onLoadError(int handle, NativeLoadError error);

  void onFullscreenChanged(int handle, bool isFullscreen);
}
