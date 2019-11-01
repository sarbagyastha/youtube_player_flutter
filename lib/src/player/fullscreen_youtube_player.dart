import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../player/youtube_player.dart';
import '../utils/youtube_player_controller.dart';
import '../utils/youtube_player_flags.dart';
import '../widgets/widgets.dart';

class FullScreenYoutubePlayer extends StatefulWidget {
  final YoutubePlayerController controller;

  /// The duration for which controls in the player will be visible.
  ///
  /// Default is 3 seconds.
  final Duration controlsTimeOut;

  /// Overrides the default buffering indicator for the player.
  final Widget bufferIndicator;

  /// Overrides default colors of the progress bar, takes [ProgressColors].
  final ProgressBarColors progressColors;

  final VoidCallback onReady;

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
    @required this.controller,
    this.controlsTimeOut = const Duration(seconds: 3),
    this.bufferIndicator,
    this.progressColors,
    this.onReady,
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
    widget.controller.updateValue(
      widget.controller.value.copyWith(isFullScreen: true),
    );
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
    widget.controller.updateValue(
      widget.controller.value.copyWith(isFullScreen: false),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: widget.controller,
      flags: widget.flags.copyWith(
        showVideoProgressIndicator: false,
      ),
      actionsPadding: widget.actionsPadding,
      bottomActions: widget.bottomActions,
      bufferIndicator: widget.bufferIndicator,
      controlsTimeOut: widget.controlsTimeOut,
      liveUIColor: widget.liveUIColor,
      onReady: widget.onReady,
      progressColors: widget.progressColors,
      thumbnailUrl: widget.thumbnailUrl,
      topActions: widget.topActions,
    );
  }
}
