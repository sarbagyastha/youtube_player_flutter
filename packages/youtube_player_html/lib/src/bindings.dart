// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// Typed bindings for the parts of the YouTube IFrame Player API the plugin
// touches directly. See https://developers.google.com/youtube/iframe_api_reference

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// `window.YT`, once the API script has loaded.
@JS('YT')
external YTNamespace? get yt;

/// The `YT` namespace.
extension type YTNamespace._(JSObject _) implements JSObject {
  /// `YT.Player`, present once the API is ready.
  @JS('Player')
  external JSFunction? get player;
}

/// `YT.Player`.
@JS('YT.Player')
extension type YTPlayer._(JSObject _) implements JSObject {
  /// Attaches a player to an existing `enablejsapi=1` iframe.
  external factory(web.HTMLIFrameElement iframe, YTPlayerOptions options);

  // The getters below return `undefined` while the player is not connected
  // to its iframe (before the embed initializes, or while it reloads), so
  // they are nullable.

  /// `getCurrentTime()`: elapsed seconds.
  external double? getCurrentTime();

  /// `getDuration()`: video length in seconds, `0` until metadata loads.
  external double? getDuration();

  /// `getVideoLoadedFraction()`: buffered share of the video, `0..1`.
  external double? getVideoLoadedFraction();

  /// `getPlaybackRate()`: current playback rate.
  external double? getPlaybackRate();

  /// `getVolume()`: volume `0..100`.
  external int? getVolume();

  /// `isMuted()`: whether the player is muted.
  external bool? isMuted();

  /// `getVideoData()`: id, title and author of the current video.
  external YTVideoData? getVideoData();

  /// `destroy()`: removes the player and its listeners.
  external void destroy();
}

/// Constructor options.
extension type YTPlayerOptions._(JSObject _) implements JSObject {
  /// Creates options with [events].
  external factory({YTEvents events});
}

/// Event listeners.
extension type YTEvents._(JSObject _) implements JSObject {
  /// Creates the listener map.
  external factory({
    JSFunction onReady,
    JSFunction onStateChange,
    JSFunction onPlaybackRateChange,
    JSFunction onPlaybackQualityChange,
    JSFunction onError,
    JSFunction onApiChange,
    JSFunction onAutoplayBlocked,
  });
}

/// The event object passed to listeners.
extension type YTEvent._(JSObject _) implements JSObject {
  /// Event payload (state / error code, rate, quality).
  external JSAny? get data;
}

/// Undocumented `getVideoData()` result.
extension type YTVideoData._(JSObject _) implements JSObject {
  /// The video id (`video_id`).
  @JS('video_id')
  external String? get videoId;

  /// The video title.
  external String? get title;

  /// The channel name.
  external String? get author;
}

Future<void>? _apiLoading;

/// Loads `https://www.youtube.com/iframe_api` once per page.
Future<void> loadIframeApi() => _apiLoading ??= _loadIframeApi();

/// Origins the player talks to first; warmed up once per page.
const _preconnect = [
  'https://www.youtube.com',
  'https://www.youtube-nocookie.com',
  'https://i.ytimg.com',
];

Future<void> _loadIframeApi() {
  if (yt?.player != null) return Future.value();
  final head = web.document.head!;
  for (final origin in _preconnect) {
    head.append(
      web.HTMLLinkElement()
        ..rel = 'preconnect'
        ..href = origin,
    );
  }
  final completer = Completer<void>();
  final previous = globalContext['onYouTubeIframeAPIReady'];
  globalContext['onYouTubeIframeAPIReady'] = () {
    if (previous case final JSFunction callback) callback.callAsFunction();
    if (!completer.isCompleted) completer.complete();
  }.toJS;
  final script = web.HTMLScriptElement()
    ..src = 'https://www.youtube.com/iframe_api'
    ..async = true;
  script.onerror = (web.Event _) {
    _apiLoading = null;
    if (!completer.isCompleted) {
      completer.completeError(StateError('Failed to load ${script.src}'));
    }
  }.toJS;
  web.document.head!.append(script);
  return completer.future;
}
