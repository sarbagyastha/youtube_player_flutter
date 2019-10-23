import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../enums/playback_rate.dart';
import '../enums/player_state.dart';

/// [ValueNotifier] for [YoutubePlayerController].
class YoutubePlayerValue {
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

  /// Returns the current playback quality.
  final String playbackQuality;

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
    );
  }

  @override
  String toString() {
    return '$runtimeType('
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
        'playbackQuality: $playbackQuality'
        'errorCode: $errorCode)';
  }
}

class YoutubePlayerController extends ValueNotifier<YoutubePlayerValue> {
  final String initialSource;

  YoutubePlayerController([
    this.initialSource = '',
  ]) : super(YoutubePlayerValue(isReady: false));

  static YoutubePlayerController of(BuildContext context) {
    InheritedYoutubePlayer _player =
        context.inheritFromWidgetOfExactType(InheritedYoutubePlayer);
    return _player.controller;
  }

  _evaluateJS(String javascriptString) {
    value.webViewController?.evaluateJavascript(javascriptString);
  }

  /// Updates the old [YoutubePlayerValue] with new one provided.
  void updateValue(YoutubePlayerValue newValue) => value = newValue;

  /// Plays the video.
  void play() => _evaluateJS('play()');

  /// Pauses the video.
  void pause() => _evaluateJS('pause()');

  /// Loads the video as per the [videoId] provided.
  void load({int startAt = 0}) =>
      _evaluateJS('loadById("$initialSource", $startAt)');

  /// Cues the video as per the [videoId] provided.
  void cue({int startAt = 0}) =>
      _evaluateJS('cueById("$initialSource", $startAt)');

  /// Mutes the player.
  void mute() => _evaluateJS('mute()');

  /// Un mutes the player.
  void unMute() => _evaluateJS('unMute()');

  /// Sets the volume of player.
  /// Max = 100 , Min = 0
  void setVolume(int volume) => volume >= 0 && volume <= 100
      ? _evaluateJS('setVolume($volume)')
      : throw Exception("Volume should be between 0 and 100");

  /// Seek to any position. Video auto plays after seeking.
  /// The optional allowSeekAhead parameter determines whether the player will make a new request to the server
  /// if the seconds parameter specifies a time outside of the currently buffered video data.
  /// Default allowSeekAhead = true
  void seekTo(Duration position, {bool allowSeekAhead = true}) {
    _evaluateJS('seekTo(${position.inSeconds},$allowSeekAhead)');
    play();
    updateValue(value.copyWith(position: position));
  }

  /// Sets the size in pixels of the player.
  void setSize(Size size) =>
      _evaluateJS('setSize(${size.width * 100},${size.height * 100})');

  /// Sets the playback speed for the video.
  void setPlaybackRate(double rate) => _evaluateJS('setPlaybackRate($rate)');

  /// Switches the player to full screen mode.
  void enterFullScreenMode() => updateValue(value.copyWith(isFullScreen: true));

  /// Switches the player to normal mode.
  void exitFullScreenMode() => updateValue(value.copyWith(isFullScreen: false));
}

/// An inherited widget to provide [YoutubePlayerController] to it's descendants.
class InheritedYoutubePlayer extends InheritedWidget {
  const InheritedYoutubePlayer({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        super(key: key, child: child);

  final YoutubePlayerController controller;

  @override
  bool updateShouldNotify(InheritedYoutubePlayer oldPlayer) =>
      oldPlayer.controller.hashCode != controller.hashCode;
}
