import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../player/youtube_player.dart';
import '../utils/youtube_player_controller.dart';
import '../utils/youtube_player_flags.dart';
import '../widgets/widgets.dart';

class FullScreenYoutubePlayer extends StatefulWidget {
  /// Current context of the player.
  final BuildContext context;

  /// Specifies the videoId of initial video to be played.
  ///
  /// For switching videos, use `load()` or `cue()` methods from [YoutubePlayerController].
  final String initialVideoId;

  /// The duration for which controls in the player will be visible.
  ///
  /// Default is 3 seconds.
  final Duration controlsTimeOut;

  /// Overrides the default buffering indicator for the player.
  final Widget bufferIndicator;

  /// Overrides default colors of the progress bar, takes [ProgressColors].
  final ProgressBarColors progressColors;

  /// Returns [YoutubePlayerController] after being initialized.
  final void Function(YoutubePlayerController) onPlayerInitialized;

  /// Overrides color of Live UI when enabled.
  final Color liveUIColor;

  /// Adds custom top bar widgets.
  final List<Widget> topActions;

  /// Adds custom bottom bar widgets.
  final List<Widget> bottomActions;

  /// Defines padding for [topActions] and [bottomActions].
  ///
  /// Default is EdgeInsets.all(8.0).
  final EdgeInsetsGeometry actionsPadding;

  /// Thumbnail to show when player is loading.
  final String thumbnailUrl;

  /// [YoutubePlayerFlags] composes all the flags required to control the player.
  final YoutubePlayerFlags flags;

  FullScreenYoutubePlayer({
    Key key,
    @required this.context,
    @required this.initialVideoId,
    this.controlsTimeOut = const Duration(seconds: 3),
    this.bufferIndicator,
    this.progressColors,
    this.onPlayerInitialized,
    this.liveUIColor = Colors.red,
    this.topActions,
    this.bottomActions,
    this.actionsPadding = const EdgeInsets.all(8.0),
    this.thumbnailUrl,
    this.flags = const YoutubePlayerFlags(),
  }) : super(key: key);

  @override
  _FullScreenYoutubePlayerState createState() =>
      _FullScreenYoutubePlayerState();
}

class _FullScreenYoutubePlayerState extends State<FullScreenYoutubePlayer> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      context: context,
      initialVideoId: widget.initialVideoId,
      flags: widget.flags.copyWith(
        showVideoProgressIndicator: false,
      ),
      actionsPadding: widget.actionsPadding,
      bottomActions: widget.bottomActions,
      bufferIndicator: widget.bufferIndicator,
      controlsTimeOut: widget.controlsTimeOut,
      liveUIColor: widget.liveUIColor,
      onPlayerInitialized: widget.onPlayerInitialized,
      progressColors: widget.progressColors,
      thumbnailUrl: widget.thumbnailUrl,
      topActions: widget.topActions,
    );
  }
}
