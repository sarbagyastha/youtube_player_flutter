// Copyright 2019 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../enums/playback_rate.dart';
import '../enums/player_state.dart';
import '../widgets/progress_bar.dart';
import 'youtube_player_flags.dart';

/// [ValueNotifier] for [YoutubePlayerController].
class YoutubePlayerValue {
  /// The duration, current position, buffering state, error state and settings
  /// of a [YoutubePlayerController].
  YoutubePlayerValue({
    this.isReady = false,
    this.isEvaluationReady = false,
    this.showControls = false,
    this.isLoaded = false,
    this.hasPlayed = false,
    this.duration = const Duration(),
    this.position = const Duration(),
    this.buffered = 0.0,
    this.isPlaying = false,
    this.isFullScreen = false,
    this.volume = 100,
    this.playerState = PlayerState.unknown,
    this.playbackRate = PlaybackRate.normal,
    this.playbackQuality,
    this.errorCode = 0,
    this.webViewController,
    this.videoId,
    this.toggleFullScreen = false,
    this.isDragging = false,
    this.title = '',
    this.author = '',
  });

  /// Returns true when underlying web player reports ready.
  final bool isReady;

  /// Returns true when JavaScript evaluation can be triggered.
  final bool isEvaluationReady;

  /// Whether to show controls or not.
  final bool showControls;

  /// Returns true once video loads.
  final bool isLoaded;

  /// Returns true once the video start playing for the first time.
  final bool hasPlayed;

  /// The total length of the video.
  final Duration duration;

  /// The current position of the video.
  final Duration position;

  /// The position up to which the video is buffered.
  final double buffered;

  /// Reports true if video is playing.
  final bool isPlaying;

  /// Reports true if video is fullscreen.
  final bool isFullScreen;

  /// The current volume assigned for the player.
  final int volume;

  /// The current state of the player defined as [PlayerState].
  final PlayerState playerState;

  /// The current video playback rate defined as [PlaybackRate].
  final double playbackRate;

  /// Reports the error code as described [here](https://developers.google.com/youtube/iframe_api_reference#Events).
  ///
  /// See the onError Section.
  final int errorCode;

  /// Reports the [WebViewController].
  final WebViewController webViewController;

  /// Returns true is player has errors.
  bool get hasError => errorCode != 0;

  /// Reports the current playback quality.
  final String playbackQuality;

  /// Reports currently loaded video Id.
  final String videoId;

  /// Returns true if fullscreen mode is just toggled.
  final bool toggleFullScreen;

  /// Returns true if [ProgressBar] is being dragged.
  final bool isDragging;

  /// Returns title of the video.
  final String title;

  /// Returns author of the video.
  /// i.e. Channel Name
  final String author;

  /// Creates new [YoutubePlayerValue] with assigned parameters and overrides
  /// the old one.
  YoutubePlayerValue copyWith({
    bool isReady,
    bool isEvaluationReady,
    bool showControls,
    bool isLoaded,
    bool hasPlayed,
    Duration duration,
    Duration position,
    double buffered,
    bool isPlaying,
    bool isFullScreen,
    double volume,
    PlayerState playerState,
    double playbackRate,
    String playbackQuality,
    int errorCode,
    WebViewController webViewController,
    String videoId,
    bool toggleFullScreen,
    bool isDragging,
    String title,
    String author,
  }) {
    return YoutubePlayerValue(
      isReady: isReady ?? this.isReady,
      isEvaluationReady: isEvaluationReady ?? this.isEvaluationReady,
      showControls: showControls ?? this.showControls,
      isLoaded: isLoaded ?? this.isLoaded,
      duration: duration ?? this.duration,
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
      webViewController: webViewController ?? this.webViewController,
      videoId: videoId ?? this.videoId,
      toggleFullScreen: toggleFullScreen ?? this.toggleFullScreen,
      isDragging: isDragging ?? this.isDragging,
      title: title ?? this.title,
      author: author ?? this.author,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'videoId: $videoId, '
        'title: $title, '
        'author: $author, '
        'isReady: $isReady, '
        'isEvaluationReady: $isEvaluationReady, '
        'showControls: $showControls, '
        'isLoaded: $isLoaded, '
        'duration: $duration, '
        'position: $position, '
        'buffered: $buffered, '
        'isPlaying: $isPlaying, '
        'volume: $volume, '
        'playerState: $playerState, '
        'playbackRate: $playbackRate, '
        'playbackQuality: $playbackQuality, '
        'errorCode: $errorCode)';
  }
}

/// Controls a youtube player, and provides updates when the state is
/// changing.
///
/// The video is displayed in a Flutter app by creating a [YoutubePlayer] widget.
///
/// To reclaim the resources used by the player call [dispose].
///
/// After [dispose] all further calls are ignored.
class YoutubePlayerController extends ValueNotifier<YoutubePlayerValue> {
  /// The video id with which the player initializes.
  final String initialVideoId;

  /// Composes all the flags required to control the player.
  final YoutubePlayerFlags flags;

  /// Creates [YoutubePlayerController].
  YoutubePlayerController({
    @required this.initialVideoId,
    this.flags = const YoutubePlayerFlags(),
  })  : assert(initialVideoId != null, 'initialVideoId can\'t be null.'),
        assert(flags != null),
        super(YoutubePlayerValue(isReady: false));

  /// Finds [YoutubePlayerController] in the provided context.
  static YoutubePlayerController of(BuildContext context) {
    InheritedYoutubePlayer _player =
        context.inheritFromWidgetOfExactType(InheritedYoutubePlayer);
    return _player?.controller;
  }

  _callMethod(String methodString) {
    if (value.isEvaluationReady) {
      value.webViewController?.evaluateJavascript(methodString);
    } else {
      print('The controller is not ready for method calls.');
    }
  }

  // ignore: use_setters_to_change_properties
  /// Updates the old [YoutubePlayerValue] with new one provided.
  void updateValue(YoutubePlayerValue newValue) => value = newValue;

  /// Plays the video.
  void play() => _callMethod('play()');

  /// Pauses the video.
  void pause() => _callMethod('pause()');

  /// Loads the video as per the [videoId] provided.
  void load(String videoId, {int startAt = 0}) {
    _updateValues(videoId);
    _callMethod('loadById("$videoId",$startAt)');
  }

  /// Cues the video as per the [videoId] provided.
  void cue(String videoId, {int startAt = 0}) {
    _updateValues(videoId);
    _callMethod('cueById("$videoId",$startAt)');
  }

  void _updateValues(String id) {
    if (id?.length != 11) {
      updateValue(
        value.copyWith(
          errorCode: 1,
        ),
      );
      return;
    }
    updateValue(
      value.copyWith(errorCode: 0, hasPlayed: false, videoId: id),
    );
  }

  /// Mutes the player.
  void mute() => _callMethod('mute()');

  /// Un mutes the player.
  void unMute() => _callMethod('unMute()');

  /// Sets the volume of player.
  /// Max = 100 , Min = 0
  void setVolume(int volume) => volume >= 0 && volume <= 100
      ? _callMethod('setVolume($volume)')
      : throw Exception("Volume should be between 0 and 100");

  /// Seek to any position. Video auto plays after seeking.
  /// The optional allowSeekAhead parameter determines whether the player will make a new request to the server
  /// if the seconds parameter specifies a time outside of the currently buffered video data.
  /// Default allowSeekAhead = true
  void seekTo(Duration position, {bool allowSeekAhead = true}) {
    _callMethod('seekTo(${position.inSeconds},$allowSeekAhead)');
    play();
    updateValue(value.copyWith(position: position));
  }

  /// Sets the size in pixels of the player.
  void setSize(Size size) =>
      _callMethod('setSize(${size.width}, ${size.height})');

  /// Sets the playback speed for the video.
  void setPlaybackRate(double rate) => _callMethod('setPlaybackRate($rate)');

  /// Toggles the player's full screen mode.
  void toggleFullScreenMode() =>
      updateValue(value.copyWith(toggleFullScreen: true));

  /// The title of the currently playing YouTube video.
  String get title => value.title;

  /// The author/channel of the currently playing YouTube video.
  String get author => value.author;

  /// Reloads the player.
  ///
  /// The video id will reset to [initialVideoId] after reload.
  void reload() => value.webViewController?.reload();

  /// Resets the value of [YoutubePlayerController].
  void reset() => updateValue(
        value.copyWith(
          isReady: false,
          isEvaluationReady: false,
          isFullScreen: false,
          showControls: false,
          playerState: PlayerState.unknown,
          hasPlayed: false,
          duration: Duration(),
          position: Duration(),
          buffered: 0.0,
          errorCode: 0,
          toggleFullScreen: false,
          isLoaded: false,
          isPlaying: false,
          isDragging: false,
        ),
      );
}

/// An inherited widget to provide [YoutubePlayerController] to it's descendants.
class InheritedYoutubePlayer extends InheritedWidget {
  /// Creates [InheritedYoutubePlayer]
  const InheritedYoutubePlayer({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        super(key: key, child: child);

  /// A [YoutubePlayerController] which controls the player.
  final YoutubePlayerController controller;

  @override
  bool updateShouldNotify(InheritedYoutubePlayer oldPlayer) =>
      oldPlayer.controller.hashCode != controller.hashCode;
}
