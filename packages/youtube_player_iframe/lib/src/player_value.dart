// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'enums/playback_rate.dart';
import 'enums/player_state.dart';
import 'enums/youtube_error.dart';
import 'meta_data.dart';

/// Youtube Player value
class YoutubePlayerValue {
  /// The duration, current position, buffering state, error state and settings
  /// of a [YoutubePlayerController].
  YoutubePlayerValue({
    this.fullScreenOption = const FullScreenOption(enabled: false),
    this.playerState = PlayerState.unknown,
    this.playbackRate = PlaybackRate.normal,
    this.playbackQuality,
    this.error = YoutubeError.none,
    this.metaData = const YoutubeMetaData(),
  });

  /// The initial fullscreen option.
  final FullScreenOption fullScreenOption;

  /// The current state of the player defined as [PlayerState].
  final PlayerState playerState;

  /// The current video playback rate defined as [PlaybackRate].
  final double playbackRate;

  /// Reports the error code as described [here](https://developers.google.com/youtube/iframe_api_reference#Events).
  ///
  /// See the onError Section.
  final YoutubeError error;

  /// Returns true is player has errors.
  bool get hasError => error != YoutubeError.none;

  /// Reports the current playback quality.
  final String? playbackQuality;

  /// Returns meta data of the currently loaded/cued video.
  final YoutubeMetaData metaData;

  /// Returns a copy of this value with the given fields replaced.
  YoutubePlayerValue copyWith({
    FullScreenOption? fullScreenOption,
    PlayerState? playerState,
    double? playbackRate,
    String? playbackQuality,
    YoutubeError? error,
    YoutubeMetaData? metaData,
  }) {
    return YoutubePlayerValue(
      fullScreenOption: fullScreenOption ?? this.fullScreenOption,
      playerState: playerState ?? this.playerState,
      playbackRate: playbackRate ?? this.playbackRate,
      playbackQuality: playbackQuality ?? this.playbackQuality,
      error: error ?? this.error,
      metaData: metaData ?? this.metaData,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is YoutubePlayerValue &&
            runtimeType == other.runtimeType &&
            fullScreenOption == other.fullScreenOption &&
            playerState == other.playerState &&
            playbackRate == other.playbackRate &&
            playbackQuality == other.playbackQuality &&
            error == other.error &&
            metaData == other.metaData;
  }

  @override
  int get hashCode => Object.hash(
        fullScreenOption,
        playerState,
        playbackRate,
        playbackQuality,
        error,
        metaData,
      );

  @override
  String toString() {
    return '$runtimeType('
        'metaData: ${metaData.toString()}, '
        'playerState: $playerState, '
        'playbackRate: $playbackRate, '
        'playbackQuality: $playbackQuality, '
        'isFullScreen: ${fullScreenOption.enabled}, '
        'error: $error)';
  }
}

/// The fullscreen option.
class FullScreenOption {
  /// Creates [FullScreenOption].
  const FullScreenOption({
    required this.enabled,
    this.locked = false,
  });

  /// Denotes that the fullscreen mode is currently enabled.
  final bool enabled;

  /// Denotes that the fullscreen mode is currently locked for auto update.
  final bool locked;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FullScreenOption &&
            runtimeType == other.runtimeType &&
            enabled == other.enabled &&
            locked == other.locked;
  }

  @override
  int get hashCode => enabled.hashCode ^ locked.hashCode;

  /// Returns a copy of this option with the given fields replaced.
  FullScreenOption copyWith({bool? enabled, bool? locked}) {
    return FullScreenOption(
      enabled: enabled ?? this.enabled,
      locked: locked ?? this.locked,
    );
  }

  @override
  String toString() => 'FullScreenOption(enabled: $enabled, locked: $locked)';
}
