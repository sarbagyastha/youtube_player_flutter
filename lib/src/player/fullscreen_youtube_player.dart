// Copyright 2019 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../player/youtube_player.dart';
import '../utils/youtube_meta_data.dart';
import '../utils/youtube_player_controller.dart';
import '../utils/youtube_player_flags.dart';
import '../widgets/widgets.dart';

/// Shows [YoutubePlayer] in fullScreen landscape mode.
Future<void> showFullScreenYoutubePlayer({
  @required BuildContext context,
  @required String videoId,
  EdgeInsetsGeometry actionsPadding,
  List<Widget> topActions,
  List<Widget> bottomActions,
  Widget bufferIndicator,
  Duration controlsTimeOut,
  Color liveUIColor,
  void Function(YoutubePlayerController) onReady,
  void Function(YoutubeMetaData) onEnded,
  ProgressBarColors progressColors,
  String thumbnailUrl,
}) async =>
    await Navigator.push(
      context,
      _YoutubePageRoute(
        builder: (context) => _FullScreenYoutubePlayer(
          videoId: videoId,
          actionsPadding: actionsPadding,
          topActions: topActions,
          bottomActions: bottomActions,
          bufferIndicator: bufferIndicator,
          controlsTimeOut: controlsTimeOut,
          liveUIColor: liveUIColor,
          onReady: onReady,
          onEnded: onEnded,
          progressColors: progressColors,
          thumbnailUrl: thumbnailUrl,
        ),
      ),
    );

class _FullScreenYoutubePlayer extends StatefulWidget {
  /// {@macro youtube_player_flutter.videoId}
  final String videoId;

  /// {@macro youtube_player_flutter.controlsTimeOut}
  final Duration controlsTimeOut;

  /// {@macro youtube_player_flutter.bufferIndicator}
  final Widget bufferIndicator;

  /// {@macro youtube_player_flutter.progressColors}
  final ProgressBarColors progressColors;

  /// {@macro youtube_player_flutter.onReady}
  final void Function(YoutubePlayerController) onReady;

  /// {@macro youtube_player_flutter.onEnded}
  final void Function(YoutubeMetaData) onEnded;

  /// {@macro youtube_player_flutter.liveUIColor}
  final Color liveUIColor;

  /// {@macro youtube_player_flutter.topActions}
  final List<Widget> topActions;

  /// {@macro youtube_player_flutter.bottomActions}
  final List<Widget> bottomActions;

  /// {@macro youtube_player_flutter.actionsPadding}
  final EdgeInsetsGeometry actionsPadding;

  /// {@macro youtube_player_flutter.thumbnailUrl}
  final String thumbnailUrl;

  const _FullScreenYoutubePlayer({
    Key key,
    @required this.videoId,
    this.controlsTimeOut = const Duration(seconds: 3),
    this.bufferIndicator,
    this.progressColors,
    this.onReady,
    this.onEnded,
    this.liveUIColor = Colors.red,
    this.topActions,
    this.bottomActions,
    this.actionsPadding = const EdgeInsets.all(8.0),
    this.thumbnailUrl,
  }) : super(key: key);

  @override
  _FullScreenYoutubePlayerState createState() =>
      _FullScreenYoutubePlayerState();
}

class _FullScreenYoutubePlayerState extends State<_FullScreenYoutubePlayer> {
  YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: controller,
      showVideoProgressIndicator: false,
      actionsPadding: widget.actionsPadding,
      bottomActions: widget.bottomActions,
      bufferIndicator: widget.bufferIndicator,
      controlsTimeOut: widget.controlsTimeOut,
      liveUIColor: widget.liveUIColor,
      onReady: () => widget.onReady(controller),
      onEnded: widget.onEnded,
      progressColors: widget.progressColors,
      thumbnailUrl: widget.thumbnailUrl,
      topActions: widget.topActions,
    );
  }

  @override
  void initState() {
    super.initState();
    controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
      ),
    );

    controller.value.copyWith(isFullScreen: true);

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

    controller.dispose();
    super.dispose();
  }
}

class _YoutubePageRoute<T> extends MaterialPageRoute<T> {
  _YoutubePageRoute({
    @required WidgetBuilder builder,
  }) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}
