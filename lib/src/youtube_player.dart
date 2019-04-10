import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/src/controls.dart';
import 'package:youtube_player_flutter/src/progress_bar.dart';
import 'package:ytview/ytview.dart';

bool _justSwitchedToFullScreen = false;

enum PlayerState {
  UN_STARTED,
  ENDED,
  PLAYING,
  PAUSED,
  BUFFERING,
  CUED,
}

class YoutubePlayer extends StatefulWidget {
  final BuildContext context;
  final YoutubePlayerController controller;
  final double width;
  final double aspectRatio;
  final Duration controlsTimeOut;
  final bool autoPlay;
  final Widget bufferIndicator;
  final bool showVideoProgressIndicator;
  final ProgressColors progressColors;
  final Color videoProgressIndicatorColor;

  YoutubePlayer({
    Key key,
    @required this.context,
    @required this.controller,
    this.width,
    this.aspectRatio = 16 / 9,
    this.autoPlay = true,
    this.controlsTimeOut = const Duration(seconds: 3),
    this.bufferIndicator,
    this.showVideoProgressIndicator = false,
    this.videoProgressIndicatorColor = Colors.red,
    this.progressColors,
  }) : super(key: key);

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
  String _newSource;

  WebViewController _oldWebController;
  WebViewController _currentWebController;
  Duration _oldPosition;

  @override
  void initState() {
    super.initState();
    ytController = widget.controller;
    controller.addListener(listener);
    _showControls.addListener(() {
      _timer?.cancel();
      if (_showControls.value)
        _timer =
            Timer(widget.controlsTimeOut, () => _showControls.value = false);
    });
  }

  void listener() async {
    if (controller.value.newSource != null) {
      _newSource = controller.value.newSource;
      _currentWebController = controller.value.webViewController;
      controller = YoutubePlayerController(initialSource: _newSource);
      controller.value = controller.value.copyWith(webViewController: _currentWebController);
      controller.load(source: _newSource);
      controller.value = controller.value.copyWith(newSource: null);
    }
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
    if (widget.controller.value.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
    }
    if (!widget.controller.value.isFullScreen && _isFullScreen) {
      Navigator.of(context).pop();
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
          TouchShutter(_showControls),
          controller.value.position > Duration(milliseconds: 100) &&
                  !_showControls.value &&
                  widget.showVideoProgressIndicator &&
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomBar(
              controller,
              _showControls,
              widget.aspectRatio,
              widget.progressColors,
            ),
          ),
          Center(
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

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    _oldWebController = controller.value.webViewController;
    _justSwitchedToFullScreen = false;
    _oldPosition = controller.value.position;
    controller.pause();

    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
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

    await Navigator.of(context).push(route);

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
    return WebView(
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
        widget.controller.value =
            widget.controller.value.copyWith(webViewController: webController);
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

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
    this.newSource,
  });

  final bool isReady;
  final bool isLoaded;
  final bool hasPlayed;
  final Duration duration;
  final Duration position;
  final double buffered;
  final bool isPlaying;
  final bool isFullScreen;
  final int volume;
  final PlayerState playerState;
  final int errorCode;
  final WebViewController webViewController;
  final String newSource;

  bool get hasError => errorCode != 0;

  YoutubePlayerValue copyWith({
    bool isReady,
    bool isBuilt,
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
    String newSource,
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
      newSource: newSource ?? this.newSource,
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

  YoutubePlayerController({
    this.initialSource,
  }) : super(YoutubePlayerValue(isReady: false));

  void play() =>
      value.webViewController.evaluateJavascript('player.playVideo()');

  void pause() =>
      value.webViewController.evaluateJavascript('player.pauseVideo()');

  void load({String source, int startAt = 0}) =>
      value.webViewController.evaluateJavascript(
          'player.loadVideoById("${source ?? initialSource}", $startAt)');

  void cue({String source, int startAt = 0}) =>
      value.webViewController.evaluateJavascript(
          'player.cueVideoById("${source ?? initialSource}", $startAt)');

  void mute() => value.webViewController.evaluateJavascript('player.mute()');

  void unMute() =>
      value.webViewController.evaluateJavascript('player.unMute()');

  /// Sets the volume of player.
  /// Max = 100 , Min = 0
  void setVolume(int volume) => volume >= 0 && volume <= 100
      ? value.webViewController.evaluateJavascript('player.setVolume($volume)')
      : throw Exception("Volume should be between 0 and 100");

  void seekTo(Duration position, {bool allowSeekAhead = true}) {
    value.webViewController.evaluateJavascript(
        'player.seekTo(${position.inSeconds},$allowSeekAhead)');
    play();
    value = value.copyWith(position: position);
  }

  void enterFullScreen() => value = value.copyWith(isFullScreen: true);

  void changeSource(String source) => value = value.copyWith(newSource: source);
}
