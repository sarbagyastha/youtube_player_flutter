// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as iframe;

// Direct imports for types used in default parameter values and re-exported below.
import 'package:youtube_player_iframe/src/enums/player_state.dart';
import 'package:youtube_player_iframe/src/enums/playback_rate.dart';
import 'package:youtube_player_iframe/src/meta_data.dart';

import '../enums/thumbnail_quality.dart';
import '../widgets/progress_bar.dart';
import 'youtube_player_flags.dart';

// Re-export core iframe types as part of this package's public API.
export 'package:youtube_player_iframe/src/enums/player_state.dart';
export 'package:youtube_player_iframe/src/enums/playback_rate.dart';
export 'package:youtube_player_iframe/src/meta_data.dart';

/// The state snapshot for [YoutubePlayerController].
class YoutubePlayerValue {
  /// Creates [YoutubePlayerValue].
  const YoutubePlayerValue({
    this.isReady = false,
    this.isControlsVisible = false,
    this.hasPlayed = false,
    this.position = Duration.zero,
    this.buffered = 0.0,
    this.isPlaying = false,
    this.isFullScreen = false,
    this.volume = 100,
    this.playerState = PlayerState.unknown,
    this.playbackRate = PlaybackRate.normal,
    this.playbackQuality,
    this.errorCode = 0,
    this.isDragging = false,
    this.metaData = const YoutubeMetaData(),
  });

  /// Returns true when the player is ready to accept control method calls.
  final bool isReady;

  /// Defines whether or not the controls overlay is currently visible.
  final bool isControlsVisible;

  /// Returns true once the video has started playing for the first time.
  final bool hasPlayed;

  /// The current playback position.
  final Duration position;

  /// The fraction of the video that has been buffered (0.0–1.0).
  final double buffered;

  /// Reports true if the video is currently playing.
  final bool isPlaying;

  /// Reports true if the player is in fullscreen mode.
  final bool isFullScreen;

  /// The current volume level (0–100).
  final int volume;

  /// The current state of the player.
  final PlayerState playerState;

  /// The current playback rate.
  final double playbackRate;

  /// The current playback quality, if available.
  final String? playbackQuality;

  /// The last YouTube API error code (0 means no error).
  final int errorCode;

  /// Returns true when the player has an active error.
  bool get hasError => errorCode != 0;

  /// Returns true if the [ProgressBar] is being dragged.
  final bool isDragging;

  /// Metadata for the currently loaded or cued video.
  final YoutubeMetaData metaData;

  /// Creates a copy of this value with given fields replaced.
  YoutubePlayerValue copyWith({
    bool? isReady,
    bool? isControlsVisible,
    bool? hasPlayed,
    Duration? position,
    double? buffered,
    bool? isPlaying,
    bool? isFullScreen,
    int? volume,
    PlayerState? playerState,
    double? playbackRate,
    String? playbackQuality,
    int? errorCode,
    bool? isDragging,
    YoutubeMetaData? metaData,
  }) {
    return YoutubePlayerValue(
      isReady: isReady ?? this.isReady,
      isControlsVisible: isControlsVisible ?? this.isControlsVisible,
      hasPlayed: hasPlayed ?? this.hasPlayed,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      isPlaying: isPlaying ?? this.isPlaying,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      volume: volume ?? this.volume,
      playerState: playerState ?? this.playerState,
      playbackRate: playbackRate ?? this.playbackRate,
      playbackQuality: playbackQuality ?? this.playbackQuality,
      errorCode: errorCode ?? this.errorCode,
      isDragging: isDragging ?? this.isDragging,
      metaData: metaData ?? this.metaData,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'metaData: $metaData, '
        'isReady: $isReady, '
        'isControlsVisible: $isControlsVisible, '
        'position: ${position.inSeconds}s, '
        'buffered: $buffered, '
        'isPlaying: $isPlaying, '
        'volume: $volume, '
        'playerState: $playerState, '
        'playbackRate: $playbackRate, '
        'playbackQuality: $playbackQuality, '
        'errorCode: $errorCode)';
  }
}

/// Controls a YouTube player and provides state updates via [ValueNotifier].
///
/// The video is displayed by creating a [YoutubePlayer] widget.
/// Call [dispose] to release resources when done.
class YoutubePlayerController extends ValueNotifier<YoutubePlayerValue> {
  /// The video ID used to initialise the player.
  final String initialVideoId;

  /// Configuration flags for the player.
  final YoutubePlayerFlags flags;

  /// The underlying iframe controller. Exposed for advanced use cases.
  late final iframe.YoutubePlayerController iframeController;

  StreamSubscription<iframe.YoutubePlayerValue>? _valueSub;
  StreamSubscription<iframe.YoutubeVideoState>? _videoStateSub;

  /// Creates [YoutubePlayerController].
  YoutubePlayerController({
    required this.initialVideoId,
    this.flags = const YoutubePlayerFlags(),
  }) : super(const YoutubePlayerValue()) {
    iframeController = iframe.YoutubePlayerController.fromVideoId(
      videoId: initialVideoId,
      autoPlay: flags.autoPlay,
      startSeconds: flags.startAt.toDouble(),
      endSeconds: flags.endAt?.toDouble(),
      params: flags.toParams(),
    );
    _bridgeStreams();
  }

  void _bridgeStreams() {
    _valueSub = iframeController.stream.listen((iframeValue) {
      final ps = iframeValue.playerState;
      updateValue(value.copyWith(
        isReady: ps != PlayerState.unknown && ps != PlayerState.unStarted,
        hasPlayed: value.hasPlayed || ps == PlayerState.playing,
        isPlaying: ps == PlayerState.playing,
        isFullScreen: iframeValue.fullScreenOption.enabled,
        playerState: ps,
        playbackRate: iframeValue.playbackRate,
        playbackQuality: iframeValue.playbackQuality,
        errorCode: iframeValue.error.code,
        metaData: iframeValue.metaData,
      ));
    });

    _videoStateSub = iframeController.videoStateStream.listen((state) {
      updateValue(value.copyWith(
        position: state.position,
        buffered: state.loadedFraction,
      ));
    });
  }

  /// Finds the nearest [YoutubePlayerController] in [context].
  static YoutubePlayerController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedYoutubePlayer>()
        ?.controller;
  }

  /// Replaces the current state value and notifies listeners.
  // ignore: use_setters_to_change_properties
  void updateValue(YoutubePlayerValue newValue) => value = newValue;

  /// Plays the video.
  Future<void> play() => iframeController.playVideo();

  /// Pauses the video.
  Future<void> pause() => iframeController.pauseVideo();

  /// Loads and plays the video with the given [videoId].
  Future<void> load(String videoId, {int startAt = 0, int? endAt}) {
    if (videoId.length != 11) {
      updateValue(value.copyWith(errorCode: 1));
      return Future.value();
    }
    updateValue(value.copyWith(errorCode: 0, hasPlayed: false));
    return iframeController.loadVideoById(
      videoId: videoId,
      startSeconds: startAt.toDouble(),
      endSeconds: endAt?.toDouble(),
    );
  }

  /// Cues the video with the given [videoId] without auto-playing.
  Future<void> cue(String videoId, {int startAt = 0, int? endAt}) {
    if (videoId.length != 11) {
      updateValue(value.copyWith(errorCode: 1));
      return Future.value();
    }
    updateValue(value.copyWith(errorCode: 0, hasPlayed: false));
    return iframeController.cueVideoById(
      videoId: videoId,
      startSeconds: startAt.toDouble(),
      endSeconds: endAt?.toDouble(),
    );
  }

  /// Mutes the player.
  Future<void> mute() => iframeController.mute();

  /// Unmutes the player.
  Future<void> unMute() => iframeController.unMute();

  /// Sets the player volume. Must be between 0 and 100.
  Future<void> setVolume(int volume) {
    assert(volume >= 0 && volume <= 100, 'Volume must be between 0 and 100');
    updateValue(value.copyWith(volume: volume));
    return iframeController.setVolume(volume);
  }

  /// Seeks to [position] in the video.
  ///
  /// If [allowSeekAhead] is true, the player may make a new network request
  /// when the target is outside the buffered range.
  Future<void> seekTo(Duration position, {bool allowSeekAhead = true}) async {
    updateValue(value.copyWith(position: position));
    await iframeController.seekTo(
      seconds: position.inMilliseconds / 1000,
      allowSeekAhead: allowSeekAhead,
    );
    return play();
  }

  /// Sets the playback rate (e.g. 0.5, 1.0, 1.5, 2.0).
  Future<void> setPlaybackRate(double rate) =>
      iframeController.setPlaybackRate(rate);

  /// No-op. Player size is managed by Flutter layout constraints.
  @Deprecated('Player sizing is handled by Flutter layout. Has no effect.')
  void setSize(Size size) {}

  /// No-op. Player sizing is handled by Flutter layout constraints.
  @Deprecated('Player sizing is handled by Flutter layout. Has no effect.')
  void fitWidth(Size screenSize) {}

  /// No-op. Player sizing is handled by Flutter layout constraints.
  @Deprecated('Player sizing is handled by Flutter layout. Has no effect.')
  void fitHeight(Size screenSize) {}

  /// Toggles between fullscreen and normal mode.
  ///
  /// Uses [SystemChrome] orientation locks rather than the iframe's OverlayPortal
  /// mechanism, so Flutter overlay controls stay correctly aligned.
  void toggleFullScreenMode() {
    updateValue(value.copyWith(isFullScreen: !value.isFullScreen));
    if (value.isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  /// Reloads the player HTML, resetting it to [initialVideoId].
  Future<void> reload() => iframeController.load(
        params: iframeController.params,
      );

  /// Resets the controller state to defaults without reloading the player.
  void reset() => updateValue(const YoutubePlayerValue());

  /// Metadata for the currently loaded or cued video.
  YoutubeMetaData get metadata => value.metaData;

  /// Converts a fully-qualified YouTube URL to its 11-character video ID.
  static String? convertUrlToId(String url, {bool trimWhitespaces = true}) =>
      iframe.YoutubePlayerController.convertUrlToId(
        url,
        trimWhitespaces: trimWhitespaces,
      );

  /// Returns a thumbnail URL for [videoId] at the given [quality].
  static String getThumbnail({
    required String videoId,
    String quality = ThumbnailQuality.standard,
    bool webp = true,
  }) =>
      webp
          ? 'https://i3.ytimg.com/vi_webp/$videoId/$quality.webp'
          : 'https://i3.ytimg.com/vi/$videoId/$quality.jpg';

  @override
  void dispose() {
    _valueSub?.cancel();
    _videoStateSub?.cancel();
    iframeController.close();
    super.dispose();
  }
}

/// Provides [YoutubePlayerController] to its widget subtree via [InheritedWidget].
class InheritedYoutubePlayer extends InheritedWidget {
  /// Creates [InheritedYoutubePlayer].
  const InheritedYoutubePlayer({
    super.key,
    required this.controller,
    required super.child,
  });

  /// The controller available to all descendants.
  final YoutubePlayerController controller;

  @override
  bool updateShouldNotify(InheritedYoutubePlayer oldWidget) {
    return oldWidget.controller.hashCode != controller.hashCode;
  }
}
