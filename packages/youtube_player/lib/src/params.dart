// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

/// CSS `pointer-events` applied to the player iframe.
enum PointerEvents {
  /// The player reacts to pointer events.
  auto,

  /// Browser default (usually [auto]).
  initial,

  /// The player ignores pointer events (useful with custom overlays).
  none,
}

/// Color of the player's progress bar.
enum ProgressBarColor {
  /// YouTube red.
  red,

  /// White.
  white,
}

/// Player configuration, mapped onto the documented IFrame API `playerVars`.
///
/// See https://developers.google.com/youtube/player_parameters
@immutable
final class const YoutubePlayerParams({
  /// Start muted (`mute`). Required by most platforms for autoplay with sound
  /// policies.
  final bool mute = false,

  /// Preferred caption language (`cc_lang_pref`), ISO 639-1 or BCP 47.
  final String captionLanguage = 'en',

  /// Show captions by default (`cc_load_policy`).
  final bool enableCaption = true,

  /// Pointer handling of the iframe.
  final PointerEvents pointerEvents = .initial,

  /// Progress bar color (`color`).
  final ProgressBarColor color = .white,

  /// Show the player controls (`controls`).
  final bool showControls = true,

  /// Enable keyboard shortcuts (`disablekb` inverted).
  final bool enableKeyboard = kIsWeb,

  /// Show the fullscreen button (`fs`). It opens the platform's own
  /// fullscreen presentation.
  final bool showFullscreenButton = true,

  /// Player interface language (`hl`).
  final String interfaceLanguage = 'en',

  /// Show video annotations (`iv_load_policy`).
  final bool showVideoAnnotations = true,

  /// Loop playlists (`loop`). For a single video, load it as a one-item
  /// playlist.
  final bool loop = false,

  /// Overrides the embed `origin`. Defaults to the client identity derived
  /// from [appId] (native) or the page origin (web).
  final String? origin,

  /// Play inline on iOS instead of the native fullscreen player
  /// (`playsinline`).
  final bool playsInline = true,

  /// Related videos only from the same channel (`rel=0`). YouTube no longer
  /// allows turning related videos off entirely.
  final bool strictRelatedVideos = false,

  /// User-Agent override for the native WebView.
  final String? userAgent,

  /// Use `youtube-nocookie.com`.
  final bool privacyEnhancedMode = true,

  /// Interval in milliseconds between position updates while playing.
  final int videoStateUpdateInterval = 100,

  /// The client identity sent to YouTube (as `https://<appId>` Referer and
  /// origin). Defaults to the Android application id / Apple bundle id.
  /// Required on Windows and Linux.
  ///
  /// See https://developers.google.com/youtube/terms/required-minimum-functionality#embedded-player-api-client-identity
  final String? appId,

  /// URL reported to YouTube Analytics when the player is embedded inside a
  /// widget (`widget_referrer`).
  final String? widgetReferrer,

  /// Web only: create the iframe `credentialless`, required on
  /// cross-origin-isolated pages (e.g. multithreaded `--wasm` builds with
  /// COOP/COEP headers).
  final bool webCredentialless = false,

  /// Android only: orientation while the video is fullscreen.
  final FullscreenOrientation fullscreenOrientation = .landscape,

  /// Allow inspecting the player WebView (Safari / chrome://inspect).
  final bool debuggable = kDebugMode,
}) {
  /// The embed host for [privacyEnhancedMode].
  String get host => privacyEnhancedMode
      ? 'https://www.youtube-nocookie.com'
      : 'https://www.youtube.com';

  /// The documented `playerVars` for these params.
  Map<String, Object> toPlayerVars() => {
    'autoplay': 0,
    'mute': _flag(mute),
    'cc_lang_pref': captionLanguage,
    'cc_load_policy': _flag(enableCaption),
    'color': color.name,
    'controls': _flag(showControls),
    'disablekb': _flag(!enableKeyboard),
    'fs': _flag(showFullscreenButton),
    'hl': interfaceLanguage,
    'iv_load_policy': showVideoAnnotations ? 1 : 3,
    'loop': _flag(loop),
    'playsinline': _flag(playsInline),
    'rel': _flag(!strictRelatedVideos),
    'origin': ?origin,
    'widget_referrer': ?widgetReferrer,
  };

  /// Host creation parameters for the platform implementation.
  YoutubeHostParams toHostParams({String? videoId, Color? backgroundColor}) =>
      YoutubeHostParams(
        playerVars: toPlayerVars(),
        videoId: videoId,
        host: host,
        appId: appId,
        userAgent: userAgent,
        backgroundColor: backgroundColor,
        debuggable: debuggable,
        webCredentialless: webCredentialless,
        fullscreenOrientation: fullscreenOrientation,
        pointerEvents: pointerEvents.name,
        tickInterval: Duration(milliseconds: videoStateUpdateInterval),
      );

  static int _flag(bool value) => value ? 1 : 0;
}
