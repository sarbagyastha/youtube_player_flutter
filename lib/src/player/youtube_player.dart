import 'dart:async';

import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../enums/player_state.dart';
import '../enums/thumbnail_quality.dart';
import '../utils/errors.dart';
import '../utils/youtube_player_controller.dart';
import '../utils/youtube_player_flags.dart';
import '../widgets/touch_shutter.dart';
import '../widgets/widgets.dart';
import 'raw_youtube_player.dart';

/// A widget to play or stream YouTube videos using the official [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference).
///
/// In order to play live videos, set `isLive` property to true in [YoutubePlayerFlags].
///
/// {@tool sample}
///
/// Using YoutubePlayer widget:
///
/// ```dart
/// YoutubePlayer(
///    context: context,
///    videoId: "iLnmTe5Q2Qw",
///    flags: YoutubePlayerFlags(
///      autoPlay: true,
///      showVideoProgressIndicator: true,
///    ),
///    videoProgressIndicatorColor: Colors.amber,
///    progressColors: ProgressColors(
///      playedColor: Colors.amber,
///      handleColor: Colors.amberAccent,
///    ),
///    onPlayerInitialized: (controller) {
///      _controller = controller..addListener(listener);
///    },
///)
/// ```
/// {@end-tool}
class YoutubePlayer extends StatefulWidget {
  /// Current context of the player.
  final BuildContext context;

  /// The required videoId property specifies the YouTube Video ID of the video to be played.
  final String videoId;

  /// Defines the width of the player.
  ///
  /// Default is devices's width.
  final double width;

  /// Defines the aspect ratio to be assigned to the player. This property along with [width] calculates the player size.
  ///
  /// Default is 16 / 9.
  final double aspectRatio;

  /// The duration for which controls in the player will be visible.
  ///
  /// Default is 3 seconds.
  final Duration controlsTimeOut;

  /// Overrides the default buffering indicator for the player.
  final Widget bufferIndicator;

  /// Overrides default colors of the progress bar, takes [ProgressColors].
  final ProgressBarColors progressColors;

  /// Overrides default color of progress indicator shown below the player(if enabled).
  final Color progressIndicatorColor;

  /// Returns [YoutubePlayerController] after being initialized.
  final void Function(YoutubePlayerController) onPlayerInitialized;

  /// Overrides color of Live UI when enabled.
  final Color liveUIColor;

  /// Adds custom top bar widgets.
  final List<Widget> topActions;

  /// Adds custom bottom bar widgets.
  final List<Widget> bottomActions;

  /// Thumbnail to show when player is loading.
  final String thumbnailUrl;

  /// [YoutubePlayerFlags] composes all the flags required to control the player.
  final YoutubePlayerFlags flags;

  /// Video starts playing from the duration provided.
  final Duration startAt;

  YoutubePlayer({
    Key key,
    @required this.context,
    @required this.videoId,
    this.width,
    this.aspectRatio = 16 / 9,
    this.controlsTimeOut = const Duration(seconds: 3),
    this.bufferIndicator,
    this.progressIndicatorColor = Colors.red,
    this.progressColors,
    this.onPlayerInitialized,
    this.liveUIColor = Colors.red,
    this.topActions,
    this.bottomActions,
    this.thumbnailUrl,
    this.flags = const YoutubePlayerFlags(),
    this.startAt = const Duration(seconds: 0),
  }) : super(key: key);

  /// Converts fully qualified YouTube Url to video id.
  static String convertUrlToId(String url, [bool trimWhitespaces = true]) {
    assert(url?.isNotEmpty ?? false, 'Url cannot be empty');
    if (!url.contains("http") && (url.length == 11)) return url;
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

  /// Grabs YouTube video's thumbnail for provided video id.
  static String getThumbnail({
    @required String videoId,
    String quality = ThumbnailQuality.standard,
  }) =>
      'https://i3.ytimg.com/vi/$videoId/$quality';

  @override
  _YoutubePlayerState createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer> {
  YoutubePlayerController controller;

  Timer _timer;
  double _aspectRatio;
  String _currentVideoId;
  bool _firstLoad = true;
  bool _inFullScreen = false;
  StreamSubscription _connectionChecker;

  final _showControls = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadController();
    _aspectRatio = widget.aspectRatio;
    _currentVideoId = widget.videoId;
    _showControls.addListener(
      () {
        _timer?.cancel();
        if (_showControls.value)
          _timer = Timer(
            widget.controlsTimeOut,
            () => _showControls.value = false,
          );
      },
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      controller.updateValue(controller.value.copyWith(isFullScreen: false));
    });
    _connectionChecker =
        DataConnectionChecker().onStatusChange.listen((status) {
      if (status == DataConnectionStatus.connected) {
        if (controller.value.errorCode == 400) {
          controller.updateValue(controller.value.copyWith(errorCode: 0));
        }
      } else {
        controller.updateValue(controller.value.copyWith(errorCode: 400));
      }
    });
  }

  _loadController({WebViewController webController}) {
    controller = YoutubePlayerController(widget.videoId);
    if (webController != null) {
      controller.updateValue(
        controller.value.copyWith(webViewController: webController),
      );
    }
    if (widget.onPlayerInitialized != null) {
      widget.onPlayerInitialized(controller);
    }
    controller.addListener(listener);
  }

  void listener() async {
    if (controller.value.isReady &&
        controller.value.isEvaluationReady &&
        _firstLoad) {
      _firstLoad = false;
      widget.flags.autoPlay
          ? controller.load(startAt: widget.startAt.inSeconds)
          : controller.cue(startAt: widget.startAt.inSeconds);
      if (widget.flags.mute) {
        controller.mute();
      }
    }
    if (controller.value.isFullScreen && !_inFullScreen) {
      controller.pause();
      _inFullScreen = true;

      SystemChrome.setEnabledSystemUIOverlays([]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _aspectRatio = 1 / MediaQuery.of(context).size.aspectRatio;
      delayedPlay();
    }
    if (!controller.value.isFullScreen && _inFullScreen) {
      controller.pause();
      _aspectRatio = widget.aspectRatio;

      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      _inFullScreen = false;
      delayedPlay();
    }
    if (mounted) {
      setState(() {});
    }
  }

  // TODO: Resizing playing video crashes the application. Remove delay if fix is added to Flutter.
  void delayedPlay() => Future.delayed(
        Duration(seconds: 1),
        () => controller.play(),
      );

  @override
  void dispose() {
    _timer?.cancel();
    _connectionChecker?.cancel();
    controller.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentVideoId != widget.videoId) {
      _currentVideoId = widget.videoId;
      _loadController(webController: controller.value.webViewController);
      controller.load(startAt: widget.startAt.inSeconds);
    }
    return InheritedYoutubePlayer(
      controller: controller,
      child: Container(
        color: Colors.black,
        width: widget.width ?? MediaQuery.of(widget.context).size.width,
        child: _buildPlayer(
          errorWidget: Container(
            color: Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5.0),
                    Expanded(
                      child: Text(
                        errorString(controller.value.errorCode),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                Text(
                  'Error Code: ${controller.value.errorCode}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer({Widget errorWidget}) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: controller.value.hasError
          ? errorWidget
          : Stack(
              fit: StackFit.expand,
              overflow: Overflow.visible,
              children: [
                RawYoutubePlayer(
                  key: widget.key,
                  flags: widget.flags,
                ),
                if (!controller.value.hasPlayed &&
                    controller.value.playerState == PlayerState.buffering)
                  Container(
                    color: Colors.black,
                  ),
                if (!controller.value.hasPlayed && !widget.flags.hideThumbnail)
                  Image.network(
                    widget.thumbnailUrl ??
                        YoutubePlayer.getThumbnail(
                          videoId: controller.initialSource,
                        ),
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            color: Colors.black,
                          ),
                  ),
                if (!widget.flags.hideControls)
                  TouchShutter(
                    disableDragSeek: widget.flags.disableDragSeek,
                    timeOut: widget.controlsTimeOut,
                  ),
                if (!widget.flags.hideControls &&
                    controller.value.position > Duration(milliseconds: 100) &&
                    !controller.value.showControls &&
                    widget.flags.showVideoProgressIndicator &&
                    !widget.flags.isLive &&
                    !controller.value.isFullScreen)
                  Positioned(
                    bottom: -7.0,
                    left: -7.0,
                    right: -7.0,
                    child: IgnorePointer(
                      ignoring: true,
                      child: ProgressBar(
                        colors: ProgressBarColors(
                          handleColor: Colors.transparent,
                          bufferedColor: Colors.white,
                          backgroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ),
                if (!widget.flags.hideControls)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: !widget.flags.hideControls &&
                              controller.value.showControls
                          ? 1
                          : 0,
                      duration: Duration(milliseconds: 300),
                      child: widget.flags.isLive
                          ? LiveBottomBar(
                              aspectRatio: widget.aspectRatio,
                              liveUIColor: widget.liveUIColor,
                            )
                          : Row(
                              children: widget.bottomActions ??
                                  [
                                    SizedBox(width: 14.0),
                                    CurrentPosition(),
                                    SizedBox(width: 8.0),
                                    ProgressBar(isExpanded: true),
                                    RemainingDuration(),
                                    PlaybackSpeedButton(),
                                    FullScreenButton(),
                                  ],
                            ),
                    ),
                  ),
                if (!widget.flags.hideControls && controller.value.showControls)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: !widget.flags.hideControls &&
                              controller.value.showControls
                          ? 1
                          : 0,
                      duration: Duration(milliseconds: 300),
                      child: Row(
                        children: widget.topActions ?? [Container()],
                      ),
                    ),
                  ),
                if (!widget.flags.hideControls)
                  Center(
                    child: PlayPauseButton(),
                  ),
              ],
            ),
    );
  }
}
