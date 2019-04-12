import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/src/controls.dart';
import 'package:youtube_player_flutter/src/progress_bar.dart';
import 'package:ytview/ytview.dart';

bool _justSwitchedToFullScreen = false;

/// Current state of the player. Find more about it [here](https://developers.google.com/youtube/iframe_api_reference#Playback_status)
enum PlayerState {
  UN_STARTED,
  ENDED,
  PLAYING,
  PAUSED,
  BUFFERING,
  CUED,
}

typedef YoutubePlayerControllerCallback(YoutubePlayerController controller);

class YoutubePlayer extends StatefulWidget {
  /// Current context of the player.
  final BuildContext context;

  /// The required videoId property specifies the YouTube Video ID of the video to be played.
  final String videoId;

  /// Defines the width of the player.
  /// Default = Devices's Width
  final double width;

  /// Defines the aspect ratio to be assigned to the player. This property along with [width] calculates the player size.
  /// Default = 16/9
  final double aspectRatio;

  /// if set to true, hides the controls.
  /// Default = false
  final bool hideControls;

  /// The duration for which controls in the player will be visible.
  /// Default = 3 seconds
  final Duration controlsTimeOut;

  /// Define whether to auto play the video after initialization or not.
  /// Default = true
  final bool autoPlay;

  /// Overrides the default buffering indicator for the player.
  final Widget bufferIndicator;

  /// Defines whether to show or hide progress indicator below the player.
  /// Default = false
  final bool showVideoProgressIndicator;

  /// Overrides default colors of the progress bar, takes [ProgressColors].
  final ProgressColors progressColors;

  /// Overrides default color of progress indicator shown below the player(if enabled).
  final Color videoProgressIndicatorColor;

  /// Returns [YoutubePlayerController] after being initialized.
  final YoutubePlayerControllerCallback onPlayerInitialized;

  /// if true, Live Playback controls will be shown instead of default one.
  /// Default = false
  final bool isLive;

  /// Overrides color of Live UI when enabled.
  final Color liveUIColor;

  YoutubePlayer({
    Key key,
    @required this.context,
    @required this.videoId,
    this.width,
    this.aspectRatio = 16 / 9,
    this.autoPlay = true,
    this.hideControls = false,
    this.controlsTimeOut = const Duration(seconds: 3),
    this.bufferIndicator,
    this.showVideoProgressIndicator = false,
    this.videoProgressIndicatorColor = Colors.red,
    this.progressColors,
    this.onPlayerInitialized,
    this.isLive = false,
    this.liveUIColor = Colors.red,
  })  : assert(videoId.length == 11, "Invalid YouTube Video Id"),
        super(key: key);

  /// Converts fully qualified YouTube Url to video id.
  static String convertUrlToId(String url, [bool trimWhitespaces = true]) {
    if (!url.contains("http") && (url.length == 11)) return url;
    if (url == null || url.length == 0) return null;
    if (trimWhitespaces) url = url.trim();

    for (var exp in [
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$")
    ]) {
      Match match = exp.firstMatch(url);
      if (match != null && match.groupCount >= 1) return match.group(1);
    }

    return null;
  }

  @override
  _YoutubePlayerState createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer> {
  YoutubePlayerController ytController;

  YoutubePlayerController get controller => ytController;

  set controller(YoutubePlayerController c) => ytController = c;

  final _showControls = ValueNotifier<bool>(false);

  int currentPosition = 0;
  int totalDuration = 0;
  double loadedFraction = 0;
  Timer _timer;
  bool _isFullScreen = false;

  WebViewController _oldWebController;
  Duration _oldPosition;

  String _currentVideoId;

  @override
  void initState() {
    super.initState();
    _loadController();
    _currentVideoId = widget.videoId;
    _showControls.addListener(() {
      _timer?.cancel();
      if (_showControls.value)
        _timer =
            Timer(widget.controlsTimeOut, () => _showControls.value = false);
    });
  }

  _loadController({WebViewController webController}) {
    controller = YoutubePlayerController(widget.videoId);
    if (webController != null)
      controller.value =
          controller.value.copyWith(webViewController: webController);
    controller.addListener(listener);
    if (widget.onPlayerInitialized != null)
      widget.onPlayerInitialized(controller);
  }

  void listener() async {
    if (_oldWebController != null &&
        _oldWebController.hashCode !=
            controller.value.webViewController.hashCode) {
      _oldPosition = controller.value.position;
    }
    if ((_oldWebController != null) && _justSwitchedToFullScreen) {
      _justSwitchedToFullScreen = false;
      controller.seekTo(_oldPosition);
    }
    if (controller.value.isLoaded && mounted) {
      setState(() {
        currentPosition = controller.value.position.inMilliseconds;
        totalDuration = controller.value.duration.inMilliseconds;
        loadedFraction = currentPosition / totalDuration;
        if (loadedFraction > 1) loadedFraction = 1;
      });
    }
    if (controller.value.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
    }
    if (!controller.value.isFullScreen && _isFullScreen) {
      Navigator.of(context).pop("");
      _isFullScreen = false;
      Future.delayed(
        Duration(milliseconds: 500),
        () => controller
            .seekTo(Duration(milliseconds: _oldPosition.inMilliseconds + 500)),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentVideoId != widget.videoId) {
      _currentVideoId = widget.videoId;
      _loadController(webController: controller.value.webViewController);
      controller.load();
      Future.delayed(Duration(milliseconds: 500),
          () => controller.seekTo(Duration(seconds: 0)));
    }
    return Container(
      width: widget.width ?? MediaQuery.of(widget.context).size.width,
      child: _buildPlayer(widget.aspectRatio),
    );
  }

  Widget _buildPlayer(double _aspectRatio) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        overflow: Overflow.visible,
        children: <Widget>[
          _Player(
            controller: controller,
            autoPlay: widget.autoPlay,
          ),
          controller.value.hasPlayed
              ? Container()
              : Image.network(
                  "https://i3.ytimg.com/vi/${controller.initialSource}/sddefault.jpg",
                  fit: BoxFit.cover,
                ),
          widget.hideControls
              ? Container()
              : TouchShutter(
                  controller,
                  _showControls,
                ),
          widget.hideControls
              ? Container()
              : controller.value.position > Duration(milliseconds: 100) &&
                      !_showControls.value &&
                      widget.showVideoProgressIndicator &&
                      !widget.isLive &&
                      !controller.value.isFullScreen
                  ? Positioned(
                      bottom: -27.9,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: true,
                        child: ProgressBar(
                          controller,
                          colors: ProgressColors(
                            handleColor: Colors.transparent,
                            playedColor: widget.videoProgressIndicatorColor,
                          ),
                        ),
                      ),
                    )
                  : Container(),
          widget.hideControls
              ? Container()
              : Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: widget.isLive
                      ? LiveBottomBar(
                          controller,
                          _showControls,
                          widget.aspectRatio,
                          widget.liveUIColor,
                        )
                      : BottomBar(
                          controller,
                          _showControls,
                          widget.aspectRatio,
                          widget.progressColors,
                        ),
                ),
          widget.hideControls
              ? Container()
              : Center(
                  child: PlayPauseButton(
                    controller,
                    _showControls,
                    widget.bufferIndicator ??
                        Container(
                          width: 70.0,
                          height: 70.0,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _pushFullScreenWidget(BuildContext context) async {
    _oldWebController = controller.value.webViewController;
    _justSwitchedToFullScreen = false;
    _oldPosition = controller.value.position;
    controller.pause();

    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final TransitionRoute<String> route = PageRouteBuilder<String>(
      maintainState: true,
      settings: RouteSettings(isInitialRoute: false),
      pageBuilder: (context, animation, secondAnimation) => AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget child) {
              return Scaffold(
                resizeToAvoidBottomPadding: false,
                body: Container(
                  alignment: Alignment.center,
                  color: Colors.black,
                  child: _buildPlayer(MediaQuery.of(context).size.aspectRatio),
                ),
              );
            },
          ),
    );

    SystemChrome.setEnabledSystemUIOverlays([]);
    if (isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    String popValue = await Navigator.of(context).push(route);
    if (popValue == null) _isFullScreen = false;

    controller.value = controller.value
        .copyWith(isFullScreen: false, webViewController: _oldWebController);

    Future.delayed(
      Duration(milliseconds: 500),
      () {
        SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
        SystemChrome.setPreferredOrientations(
          [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        );
      },
    );

    if (popValue == null)
      Future.delayed(
        Duration(milliseconds: 500),
        () => controller
            .seekTo(Duration(milliseconds: _oldPosition.inMilliseconds + 500)),
      );
  }
}

class _Player extends StatefulWidget {
  final YoutubePlayerController controller;
  final bool autoPlay;

  _Player({
    this.controller,
    this.autoPlay,
  });

  @override
  __PlayerState createState() => __PlayerState();
}

class __PlayerState extends State<_Player> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: WebView(
        initialUrl: "https://sarbagyadhaubanjar.github.io/youtube_player",
        javascriptMode: JavascriptMode.unrestricted,
        javascriptChannels: <JavascriptChannel>[
          JavascriptChannel(
            name: 'Ready',
            onMessageReceived: (JavascriptMessage message) {
              widget.controller.value =
                  widget.controller.value.copyWith(isReady: true);
              if (widget.autoPlay)
                widget.controller.load();
              else
                widget.controller.cue();
            },
          ),
          JavascriptChannel(
            name: 'StateChange',
            onMessageReceived: (JavascriptMessage message) {
              switch (message.message) {
                case '-1':
                  widget.controller.value = widget.controller.value.copyWith(
                      playerState: PlayerState.UN_STARTED, isLoaded: true);
                  _justSwitchedToFullScreen = true;
                  break;
                case '0':
                  widget.controller.value = widget.controller.value
                      .copyWith(playerState: PlayerState.ENDED);
                  break;
                case '1':
                  widget.controller.value = widget.controller.value.copyWith(
                    playerState: PlayerState.PLAYING,
                    isPlaying: true,
                    hasPlayed: true,
                    errorCode: 0,
                  );
                  break;
                case '2':
                  widget.controller.value = widget.controller.value.copyWith(
                    playerState: PlayerState.PAUSED,
                    isPlaying: false,
                  );
                  break;
                case '3':
                  widget.controller.value = widget.controller.value
                      .copyWith(playerState: PlayerState.BUFFERING);
                  break;
                case '5':
                  widget.controller.value = widget.controller.value
                      .copyWith(playerState: PlayerState.CUED);
                  break;
                default:
                  throw Exception("Invalid player state obtained.");
              }
            },
          ),
          JavascriptChannel(
            name: 'PlaybackQualityChange',
            onMessageReceived: (JavascriptMessage message) {
              print("PlaybackQualityChange ${message.message}");
            },
          ),
          JavascriptChannel(
            name: 'PlaybackRateChange',
            onMessageReceived: (JavascriptMessage message) {
              print("PlaybackRateChange ${message.message}");
            },
          ),
          JavascriptChannel(
            name: 'Errors',
            onMessageReceived: (JavascriptMessage message) {
              widget.controller.value = widget.controller.value
                  .copyWith(errorCode: int.parse(message.message ?? 0));
            },
          ),
          JavascriptChannel(
            name: 'VideoData',
            onMessageReceived: (JavascriptMessage message) {
              var videoData = jsonDecode(message.message);
              double duration = videoData['duration'] * 1000;
              print("VideoData ${message.message}");
              widget.controller.value = widget.controller.value.copyWith(
                duration: Duration(
                  milliseconds: duration.floor(),
                ),
              );
            },
          ),
          JavascriptChannel(
            name: 'CurrentTime',
            onMessageReceived: (JavascriptMessage message) {
              double position = double.parse(message.message) * 1000;
              widget.controller.value = widget.controller.value.copyWith(
                position: Duration(
                  milliseconds: position.floor(),
                ),
              );
            },
          ),
          JavascriptChannel(
            name: 'LoadedFraction',
            onMessageReceived: (JavascriptMessage message) {
              widget.controller.value = widget.controller.value.copyWith(
                buffered: double.parse(message.message),
              );
            },
          ),
        ].toSet(),
        onWebViewCreated: (webController) {
          widget.controller.value = widget.controller.value
              .copyWith(webViewController: webController);
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// [ValueNotifier] for [YoutubePlayerController].
class YoutubePlayerValue {
  YoutubePlayerValue({
    @required this.isReady,
    this.isLoaded = false,
    this.hasPlayed = false,
    this.duration = const Duration(),
    this.position = const Duration(),
    this.buffered = 0.0,
    this.isPlaying = false,
    this.isFullScreen = false,
    this.volume = 100,
    this.playerState,
    this.errorCode,
    this.webViewController,
  });

  /// This is true when underlying web player reports ready.
  final bool isReady;

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

  /// Reports the error code as described [here](https://developers.google.com/youtube/iframe_api_reference#Events).
  /// See the onError Section.
  final int errorCode;

  /// Reports the [WebViewController].
  final WebViewController webViewController;

  /// Returns true is player has errors.
  bool get hasError => errorCode != 0;

  YoutubePlayerValue copyWith({
    bool isReady,
    bool isLoaded,
    bool hasPlayed,
    Duration duration,
    Duration position,
    double buffered,
    bool isPlaying,
    bool isFullScreen,
    double volume,
    PlayerState playerState,
    int errorCode,
    WebViewController webViewController,
  }) {
    return YoutubePlayerValue(
      isReady: isReady ?? this.isReady,
      isLoaded: isLoaded ?? this.isLoaded,
      duration: duration ?? this.duration,
      hasPlayed: hasPlayed ?? this.hasPlayed,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      isPlaying: isPlaying ?? this.isPlaying,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      volume: volume ?? this.volume,
      playerState: playerState ?? this.playerState,
      errorCode: errorCode ?? this.errorCode,
      webViewController: webViewController ?? this.webViewController,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'isReady: $isReady, '
        'isLoaded: $isLoaded, '
        'duration: $duration, '
        'position: $position, '
        'buffered: $buffered, '
        'isPlaying: $isPlaying, '
        'volume: $volume, '
        'playerState: $playerState, '
        'errorCode: $errorCode)';
  }
}

class YoutubePlayerController extends ValueNotifier<YoutubePlayerValue> {
  final String initialSource;

  YoutubePlayerController([
    this.initialSource = "",
  ]) : super(YoutubePlayerValue(isReady: false));

  /// Plays the video.
  void play() =>
      value.webViewController.evaluateJavascript('player.playVideo()');

  /// Pauses the video.
  void pause() =>
      value.webViewController.evaluateJavascript('player.pauseVideo()');

  /// Loads the video as per the [videoId] provided.
  void load({int startAt = 0}) => value.webViewController
      .evaluateJavascript('player.loadVideoById("$initialSource", $startAt)');

  /// Cues the video as per the [videoId] provided.
  void cue({int startAt = 0}) => value.webViewController
      .evaluateJavascript('player.cueVideoById("$initialSource", $startAt)');

  /// Mutes the player.
  void mute() => value.webViewController.evaluateJavascript('player.mute()');

  /// Un mutes the player.
  void unMute() =>
      value.webViewController.evaluateJavascript('player.unMute()');

  /// Sets the volume of player.
  /// Max = 100 , Min = 0
  void setVolume(int volume) => volume >= 0 && volume <= 100
      ? value.webViewController.evaluateJavascript('player.setVolume($volume)')
      : throw Exception("Volume should be between 0 and 100");

  /// Seek to any position. Video auto plays after seeking.
  /// The optional allowSeekAhead parameter determines whether the player will make a new request to the server
  /// if the seconds parameter specifies a time outside of the currently buffered video data.
  /// Default allowSeekAhead = true
  void seekTo(Duration position, {bool allowSeekAhead = true}) {
    value.webViewController.evaluateJavascript(
        'player.seekTo(${position.inSeconds},$allowSeekAhead)');
    play();
    value = value.copyWith(position: position);
  }

  /// Forces to enter fullScreen.
  void enterFullScreen() => value = value.copyWith(isFullScreen: true);
}
