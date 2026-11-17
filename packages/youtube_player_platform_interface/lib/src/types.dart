// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'element.dart';
import 'enums.dart';

/// Best-effort information about the current video.
///
/// The IFrame API does not document `getVideoData`; fields are empty when the
/// player does not expose them.
@immutable
final class const VideoData({
  /// The video id.
  final String videoId = '',

  /// The video title.
  final String title = '',

  /// The channel name.
  final String author = '',
}) {
  /// Creates a [VideoData]; omitted fields are empty.
  this;

  /// Decodes the compact wire form `{id, t, a}`.
  factory fromWire(Map<Object?, Object?> wire) => .new(
    videoId: wire['id'] as String? ?? '',
    title: wire['t'] as String? ?? '',
    author: wire['a'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      other is VideoData &&
      other.videoId == videoId &&
      other.title == title &&
      other.author == author;

  @override
  int get hashCode => Object.hash(videoId, title, author);

  @override
  String toString() => 'VideoData($videoId, "$title" by $author)';
}

/// View properties of a 360° video.
///
/// See https://developers.google.com/youtube/iframe_api_reference#Spherical_Video_Controls
@immutable
final class const SphericalProperties({
  /// Horizontal angle in degrees, `[0, 360)`.
  final double? yaw,

  /// Vertical angle in degrees, `[-90, 90]`.
  final double? pitch,

  /// Clockwise rotation in degrees, `[-180, 180]`.
  final double? roll,

  /// Field of view in degrees along the longer edge, `[30, 120]`.
  final double? fov,

  /// Whether device orientation drives the view on supported mobile devices.
  /// Only meaningful when setting properties.
  final bool? enableOrientationSensor,
}) {
  /// Creates a [SphericalProperties].
  this;

  /// Decodes the object returned by `getSphericalProperties()`.
  factory fromJson(Map<Object?, Object?> json) => .new(
    yaw: (json['yaw'] as num?)?.toDouble(),
    pitch: (json['pitch'] as num?)?.toDouble(),
    roll: (json['roll'] as num?)?.toDouble(),
    fov: (json['fov'] as num?)?.toDouble(),
  );

  /// Encodes the object passed to `setSphericalProperties()`.
  Map<String, Object> toJson() => {
    'yaw': ?yaw,
    'pitch': ?pitch,
    'roll': ?roll,
    'fov': ?fov,
    'enableOrientationSensor': ?enableOrientationSensor,
  };

  /// Whether the player returned no properties (non-360° video).
  bool get isEmpty =>
      yaw == null && pitch == null && roll == null && fov == null;

  @override
  bool operator ==(Object other) =>
      other is SphericalProperties &&
      other.yaw == yaw &&
      other.pitch == pitch &&
      other.roll == roll &&
      other.fov == fov &&
      other.enableOrientationSensor == enableOrientationSensor;

  @override
  int get hashCode =>
      Object.hash(yaw, pitch, roll, fov, enableOrientationSensor);
}

/// A failure to load the player page or the IFrame API itself (network, TLS,
/// blocked host). Video-level errors are reported as [YoutubeError] instead.
@immutable
final class const YoutubeLoadError({
  /// Platform error code (`-1` when unavailable).
  final int code = -1,

  /// Human readable description.
  required final String description,

  /// The URL that failed, if known.
  final String? url,
}) {
  /// Creates a [YoutubeLoadError].
  this;

  @override
  String toString() => 'YoutubeLoadError($code, $description, $url)';
}

/// Everything a platform needs to create a player host.
@immutable
final class const YoutubeHostParams({
  /// IFrame API `playerVars`, already encoded. `origin` and `widget_referrer`
  /// are filled in by the host when absent.
  required final Map<String, Object> playerVars,

  /// Video to load initially, if any.
  final String? videoId,

  /// Player host, `https://www.youtube.com` or
  /// `https://www.youtube-nocookie.com`.
  final String host = 'https://www.youtube.com',

  /// App identifier used as the client identity (HTTP Referer / origin).
  /// When `null`, native hosts read the bundle / package identifier.
  final String? appId,

  /// User-Agent override for the native WebView.
  final String? userAgent,

  /// Background shown behind the player before the video renders.
  final Color? backgroundColor,

  /// Allow WebView inspection (Safari Web Inspector / chrome://inspect).
  final bool debuggable = false,

  /// Web only: create the iframe with the `credentialless` attribute so it
  /// works on cross-origin isolated pages (e.g. multithreaded Wasm).
  final bool webCredentialless = false,

  /// Android only: orientation while presenting fullscreen.
  final FullscreenOrientation fullscreenOrientation = .landscape,

  /// CSS `pointer-events` of the player iframe (`auto`, `none`, `initial`).
  final String pointerEvents = 'initial',

  /// Minimum interval between progress ticks while the video plays.
  final Duration tickInterval = const Duration(milliseconds: 250),

  /// Player UI elements hidden when the player loads. Native only.
  final Set<PlayerElement> hiddenElements = const {},

  /// Custom elements, in addition to [PlayerElement.values], that clicks are
  /// matched against. Native only.
  final Set<PlayerElement> customElements = const {},

  /// Whether clicks on non-link elements (e.g. the share button) are held
  /// until `YoutubePlayerHost.resolveClick`. Links are always reported
  /// through `YoutubePlayerHost.navigations`. Native only.
  final bool interceptButtons = false,
});

/// A click on the player UI that would leave the player or open one of
/// YouTube's own panels.
@immutable
final class const NavigationRequest({
  /// Where the click leads, or `null` for a button that acts inside the
  /// player (e.g. share).
  required final Uri? uri,

  /// The element that was clicked, or [PlayerElement.unknown].
  final PlayerElement element = PlayerElement.unknown,

  /// Identifies a held click; pass it to `YoutubePlayerHost.resolveClick`.
  /// `null` for links, which the host has already blocked.
  final int? clickId,
}) {
  /// Creates a [NavigationRequest].
  this;

  /// Decodes the `click` wire message `{id, n, u}`.
  static NavigationRequest? fromWire(Object? wire) {
    if (wire is! Map) return null;
    final url = wire['u'];
    final uri = url is String && url.isNotEmpty ? Uri.tryParse(url) : null;
    final id = wire['id'];
    if (uri == null && id is! int) return null;
    final name = wire['n'];
    return NavigationRequest(
      uri: uri,
      element: name is String ? PlayerElement.byName(name) : .unknown,
      clickId: uri == null ? id as int : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NavigationRequest &&
      other.uri == uri &&
      other.element == element &&
      other.clickId == clickId;

  @override
  int get hashCode => Object.hash(uri, element, clickId);

  @override
  String toString() => 'NavigationRequest($uri, ${element.name}, $clickId)';
}
