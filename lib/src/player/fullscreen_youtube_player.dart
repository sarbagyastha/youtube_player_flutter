import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../youtube_player_flutter.dart';

Future<Duration> showFullScreenYoutubePlayer({
  @required BuildContext context,
  @required String videoId,
  double width,
  double aspectRatio = 16 / 9,
  Duration controlsTimeOut = const Duration(seconds: 3),
  Widget bufferIndicator,
  Color progressIndicatorColor = Colors.red,
  ProgressBarColors progressColors,
  void Function(YoutubePlayerController) onPlayerInitialized,
  Color liveUIColor = Colors.red,
  List<Widget> topActions,
  List<Widget> bottomActions,
  String thumbnailUrl,
  YoutubePlayerFlags flags = const YoutubePlayerFlags(),
  Duration startAt = const Duration(seconds: 0),
  bool inFullScreen = true,
}) {
  return Navigator.push<Duration>(
    context,
    MaterialPageRoute(
      builder: (context) => _FullScreenYoutubePlayer(
        context: context,
        videoId: videoId,
        startAt: startAt,
        progressIndicatorColor: progressIndicatorColor,
        progressColors: progressColors,
        liveUIColor: liveUIColor,
        controlsTimeOut: controlsTimeOut,
        bufferIndicator: bufferIndicator,
        onPlayerInitialized: onPlayerInitialized,
        thumbnailUrl: thumbnailUrl,
        flags: flags,
        width: width,
        aspectRatio: aspectRatio,
        topActions: topActions,
        bottomActions: bottomActions,
        inFullScreen: inFullScreen,
      ),
    ),
  );
}

class _FullScreenYoutubePlayer extends StatefulWidget {
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

  _FullScreenYoutubePlayer({
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
    this.inFullScreen,
  }) : super(key: key);

  @override
  __FullScreenYoutubePlayerState createState() =>
      __FullScreenYoutubePlayerState();
}

class __FullScreenYoutubePlayerState extends State<_FullScreenYoutubePlayer> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Center(
        child: YoutubePlayer(
          context: widget.context,
          videoId: widget.videoId,
          aspectRatio: widget.aspectRatio,
          width: widget.width,
          flags: widget.flags,
          topActions: widget.topActions,
          bottomActions: widget.bottomActions,
          thumbnailUrl: widget.thumbnailUrl,
          onPlayerInitialized: widget.onPlayerInitialized,
          bufferIndicator: widget.bufferIndicator,
          controlsTimeOut: widget.controlsTimeOut,
          liveUIColor: widget.liveUIColor,
          progressColors: widget.progressColors,
          progressIndicatorColor: widget.progressIndicatorColor,
          startAt: widget.startAt,
          inFullScreen: widget.inFullScreen,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }
}
