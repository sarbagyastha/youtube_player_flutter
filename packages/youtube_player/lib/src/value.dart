// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

/// Metadata of the current video.
@immutable
final class const YoutubeMetaData({
  /// Video id.
  final String videoId = '',

  /// Video title.
  final String title = '',

  /// Channel name.
  final String author = '',

  /// Duration (grows for live streams).
  final Duration duration = .zero,
}) {
  /// Returns a copy with the given fields replaced.
  YoutubeMetaData copyWith({
    String? videoId,
    String? title,
    String? author,
    Duration? duration,
  }) => YoutubeMetaData(
    videoId: videoId ?? this.videoId,
    title: title ?? this.title,
    author: author ?? this.author,
    duration: duration ?? this.duration,
  );

  @override
  bool operator ==(Object other) =>
      other is YoutubeMetaData &&
      other.videoId == videoId &&
      other.title == title &&
      other.author == author &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(videoId, title, author, duration);

  @override
  String toString() =>
      'YoutubeMetaData($videoId, "$title" by $author, ${duration.inSeconds}s)';
}

/// Position and buffering, emitted by `videoStateStream` while playing.
@immutable
final class const YoutubeVideoState({
  /// Current playback position.
  final Duration position = .zero,

  /// Buffered fraction, `0..1`.
  final double loadedFraction = 0,
}) {
  @override
  bool operator ==(Object other) =>
      other is YoutubeVideoState &&
      other.position == position &&
      other.loadedFraction == loadedFraction;

  @override
  int get hashCode => Object.hash(position, loadedFraction);
}

/// Snapshot of the player state, emitted by `YoutubePlayerController.stream`.
@immutable
final class const YoutubePlayerValue({
  /// Whether the platform is presenting the player fullscreen.
  final bool isFullScreen = false,

  /// Playback state.
  final PlayerState playerState = .unknown,

  /// Playback rate (updated once the player confirms it).
  final double playbackRate = 1,

  /// Informational quality label (e.g. `hd720`).
  final String? playbackQuality,

  /// Last player error.
  final YoutubeError error = .none,

  /// The last page / network failure, if any.
  final YoutubeLoadError? loadError,

  /// Whether the platform blocked the last autoplay or scripted play.
  final bool isAutoplayBlocked = false,

  /// Whether the player accepts API calls.
  final bool isReady = false,

  /// Whether the player is muted.
  final bool isMuted = false,

  /// Volume `0..100`, kept while muted.
  final int volume = 100,

  /// Metadata of the current video.
  final YoutubeMetaData metaData = const YoutubeMetaData(),
}) {
  /// Whether [error] is set.
  bool get hasError => error != .none;

  /// Returns a copy with the given fields replaced.
  YoutubePlayerValue copyWith({
    bool? isFullScreen,
    PlayerState? playerState,
    double? playbackRate,
    String? playbackQuality,
    YoutubeError? error,
    YoutubeLoadError? loadError,
    bool? isAutoplayBlocked,
    bool? isReady,
    bool? isMuted,
    int? volume,
    YoutubeMetaData? metaData,
  }) => YoutubePlayerValue(
    isFullScreen: isFullScreen ?? this.isFullScreen,
    playerState: playerState ?? this.playerState,
    playbackRate: playbackRate ?? this.playbackRate,
    playbackQuality: playbackQuality ?? this.playbackQuality,
    error: error ?? this.error,
    loadError: loadError ?? this.loadError,
    isAutoplayBlocked: isAutoplayBlocked ?? this.isAutoplayBlocked,
    isReady: isReady ?? this.isReady,
    isMuted: isMuted ?? this.isMuted,
    volume: volume ?? this.volume,
    metaData: metaData ?? this.metaData,
  );

  @override
  bool operator ==(Object other) =>
      other is YoutubePlayerValue &&
      other.isFullScreen == isFullScreen &&
      other.playerState == playerState &&
      other.playbackRate == playbackRate &&
      other.playbackQuality == playbackQuality &&
      other.error == error &&
      other.loadError == loadError &&
      other.isAutoplayBlocked == isAutoplayBlocked &&
      other.isReady == isReady &&
      other.isMuted == isMuted &&
      other.volume == volume &&
      other.metaData == metaData;

  @override
  int get hashCode => Object.hash(
    isFullScreen,
    playerState,
    playbackRate,
    playbackQuality,
    error,
    loadError,
    isAutoplayBlocked,
    isReady,
    isMuted,
    volume,
    metaData,
  );

  @override
  String toString() =>
      'YoutubePlayerValue($playerState, rate: $playbackRate, '
      'fullscreen: $isFullScreen, muted: $isMuted, volume: $volume, '
      'error: $error, $metaData)';
}

/// Common playback rates. The player may support others; see
/// `YoutubePlayerController.availablePlaybackRates`.
abstract final class PlaybackRate {
  /// 2×
  static const double twice = 2;

  /// 1.75×
  static const double oneAndAThreeQuarter = 1.75;

  /// 1.5×
  static const double oneAndAHalf = 1.5;

  /// 1.25×
  static const double oneAndAQuarter = 1.25;

  /// 1×
  static const double normal = 1;

  /// 0.75×
  static const double threeQuarter = 0.75;

  /// 0.5×
  static const double half = 0.5;

  /// 0.25×
  static const double quarter = 0.25;

  /// All of the above, fastest first.
  static const List<double> all = [
    twice,
    oneAndAThreeQuarter,
    oneAndAHalf,
    oneAndAQuarter,
    normal,
    threeQuarter,
    half,
    quarter,
  ];
}

/// Thumbnail sizes served by `i.ytimg.com`.
enum ThumbnailQuality(
  /// Path segment used by YouTube.
  final String value,
) {
  /// 120×90
  defaultQuality('default'),

  /// 320×180
  medium('mqdefault'),

  /// 480×360
  high('hqdefault'),

  /// 640×480
  standard('sddefault'),

  /// Original resolution (not always available).
  max('maxresdefault'),
}

/// Thumbnail image formats.
enum ThumbnailFormat(final String _path, final String _extension) {
  /// WebP (smaller).
  webp('vi_webp', 'webp'),

  /// JPEG.
  jpeg('vi', 'jpg');

  /// Thumbnail URL for [videoId] at [quality].
  String buildUrl(String videoId, ThumbnailQuality quality) =>
      'https://i.ytimg.com/$_path/$videoId/${quality.value}.$_extension';
}
