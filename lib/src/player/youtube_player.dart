import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/src/widgets/touch_shutter.dart';

import '../../youtube_player_flutter.dart';

part 'package:youtube_player_flutter/src/utils/youtube_player_controller.dart';
part 'player.dart';

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

  /// The duration for which controls in the player will be visible.
  /// Default = 3 seconds
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

  /// Adds custom top bar widgets
  final List<Widget> topActions;

  /// Adds custom bottom bar widgets
  final List<Widget> bottomActions;

  /// Thumbnail to show when player is loading
  final String thumbnailUrl;

  /// [YoutubePlayerFlags] composes all the flags required to control the player.
  final YoutubePlayerFlags flags;

  /// Video starts playing from the duration provided.
  final Duration startAt;

  final bool inFullScreen;

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
    this.inFullScreen = false,
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

  /// Grabs YouTube video's thumbnail for provided video id.
  static String getThumbnail({
    @required String videoId,
    ThumbnailQuality quality = ThumbnailQuality.standard,
  }) =>
      'https://i3.ytimg.com/vi/$videoId/${thumbnailQualityMap[quality]}';

  @override
  _YoutubePlayerState createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer> {
  YoutubePlayerController controller;

  final _showControls = ValueNotifier<bool>(false);

  Timer _timer;

  String _currentVideoId;

  bool _inFullScreen = false;

  bool _firstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadController();
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
      _inFullScreen = widget.inFullScreen;
      controller.value = controller.value.copyWith(
        isFullScreen: widget.inFullScreen ?? false,
      );
    });
  }

  _loadController({WebViewController webController}) {
    controller = YoutubePlayerController(widget.videoId);
    if (webController != null) {
      controller.value =
          controller.value.copyWith(webViewController: webController);
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
      _inFullScreen = true;
      Duration pos = await showFullScreenYoutubePlayer(
        context: context,
        videoId: widget.videoId,
        startAt: controller.value.position,
        width: widget.width,
        topActions: widget.topActions,
        bottomActions: widget.bottomActions,
        aspectRatio: widget.aspectRatio,
        bufferIndicator: widget.bufferIndicator,
        controlsTimeOut: widget.controlsTimeOut,
        flags: YoutubePlayerFlags(
          disableDragSeek: widget.flags.disableDragSeek,
          hideFullScreenButton: widget.flags.hideFullScreenButton,
          showVideoProgressIndicator: false,
          autoPlay: widget.flags.autoPlay,
          forceHideAnnotation: widget.flags.forceHideAnnotation,
          mute: widget.flags.mute,
          hideControls: widget.flags.hideControls,
          hideThumbnail: widget.flags.hideThumbnail,
          isLive: widget.flags.isLive,
        ),
        liveUIColor: widget.liveUIColor,
        progressColors: widget.progressColors,
        thumbnailUrl: widget.thumbnailUrl,
        progressIndicatorColor: widget.progressIndicatorColor,
      );
      controller.seekTo(pos ?? Duration(seconds: 1));
      _inFullScreen = false;
      controller.exitFullScreen();
    }
    if (!controller.value.isFullScreen && _inFullScreen) {
      _inFullScreen = false;
      Navigator.pop<Duration>(context, controller.value.position);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    return _InheritedYoutubePlayer(
      controller: controller,
      child: Container(
        width: widget.width ?? MediaQuery.of(widget.context).size.width,
        child: _buildPlayer(widget.aspectRatio),
      ),
    );
  }

  Widget _thumbWidget() {
    return CachedNetworkImage(
      imageUrl: widget.thumbnailUrl ??
          YoutubePlayer.getThumbnail(
            videoId: controller.initialSource,
          ),
      fit: BoxFit.cover,
      errorWidget: (context, url, _) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Oops! Something went wrong!',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Might be an internet issue',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      placeholder: (context, _) => Container(
        color: Colors.black,
      ),
    );
  }

  Widget _buildPlayer(double _aspectRatio) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        overflow: Overflow.visible,
        children: [
          _Player(
            controller: controller,
            flags: widget.flags,
          ),
          if (!controller.value.hasPlayed &&
              controller.value.playerState == PlayerState.buffering)
            Container(
              color: Colors.black,
            ),
          if (!controller.value.hasPlayed && !widget.flags.hideThumbnail)
            _thumbWidget(),
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
                opacity: (!widget.flags.hideControls &&
                        controller.value.showControls)
                    ? 1
                    : 0,
                duration: Duration(milliseconds: 300),
                child: widget.flags.isLive
                    ? LiveBottomBar(
                        aspectRatio: widget.aspectRatio,
                        liveUIColor: widget.liveUIColor,
                        hideFullScreenButton: widget.flags.hideFullScreenButton,
                      )
                    : Row(
                        children: widget.bottomActions ??
                            [
                              SizedBox(width: 14.0),
                              CurrentPosition(),
                              ProgressBar(isExpanded: true),
                              TotalDuration(),
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
                opacity: (!widget.flags.hideControls &&
                        controller.value.showControls)
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
              child: PlayButton(),
            ),
        ],
      ),
    );
  }
}
