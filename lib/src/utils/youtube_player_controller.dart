part of 'package:youtube_player_flutter/src/player/youtube_player.dart';

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
    this.errorCode = 0,
    this.webViewController,
  });

  /// This is true when underlying web player reports ready.
  final bool isReady;

  /// This is true when JavaScript evaluation can be triggered.
  final bool isEvaluationReady;

  final bool showControls;

  /// This is true once video loads.
  final bool isLoaded;

  /// This is true once the video start playing for the first time.
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
  final PlaybackRate playbackRate;

  /// Reports the error code as described [here](https://developers.google.com/youtube/iframe_api_reference#Events).
  /// See the onError Section.
  final int errorCode;

  /// Reports the [WebViewController].
  final WebViewController webViewController;

  /// Returns true is player has errors.
  bool get hasError => errorCode != 0;

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
    PlaybackRate playbackRate,
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
        'errorCode: $errorCode)';
  }
}

class YoutubePlayerController extends ValueNotifier<YoutubePlayerValue> {
  final String initialSource;

  YoutubePlayerController([
    this.initialSource = "",
  ]) : super(YoutubePlayerValue(isReady: false));

  static YoutubePlayerController of(BuildContext context) {
    _InheritedYoutubePlayer _player =
        context.inheritFromWidgetOfExactType(_InheritedYoutubePlayer);
    return _player.controller;
  }

  _evaluateJS(String javascriptString) {
    value.webViewController?.evaluateJavascript(javascriptString);
  }

  /// Hide YouTube Player annotations like title, share button and youtube logo.
  /// It's hidden by default for iOS.
  void forceHideAnnotation() {
    if (Platform.isAndroid) {
      _evaluateJS('hideAnnotations()');
    }
  }

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
    value = value.copyWith(position: position);
  }

  /// Sets the size in pixels of the player.
  void setSize(Size size) =>
      _evaluateJS('setSize(${size.width * 100},${size.height * 100})');

  void setPlaybackRate(PlaybackRate rate) =>
      _evaluateJS('setPlaybackRate(${playbackRateMap[rate]})');

  void enterFullScreen() => value = value.copyWith(isFullScreen: true);

  void exitFullScreen() => value = value.copyWith(isFullScreen: false);
}

class _InheritedYoutubePlayer extends InheritedWidget {
  const _InheritedYoutubePlayer({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        super(
          key: key,
          child: child,
        );

  final YoutubePlayerController controller;

  @override
  bool updateShouldNotify(_InheritedYoutubePlayer oldPlayer) =>
      oldPlayer.controller.hashCode != controller.hashCode;
}
