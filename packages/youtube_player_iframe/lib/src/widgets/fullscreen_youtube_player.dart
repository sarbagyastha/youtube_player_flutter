import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/youtube_player_controller.dart';
import '../player_params.dart';
import 'youtube_player.dart';

/// A widget that plays Youtube Video is full screen mode.
///
/// See also:
///
///  * [YoutubePlayer], which play or stream Youtube Videos in normal mode.
class FullscreenYoutubePlayer extends StatefulWidget {
  /// Creates an instance of [FullscreenYoutubePlayer].
  const FullscreenYoutubePlayer({
    super.key,
    required this.videoId,
    this.startSeconds,
    this.endSeconds,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.backgroundColor,
  });

  /// The YouTube Video ID.
  final String videoId;

  /// The time in seconds when the video should start from.
  final double? startSeconds;

  /// The time in seconds when the video should end at.
  final double? endSeconds;

  /// Which gestures should be consumed by the youtube player.
  ///
  /// It is possible for other gesture recognizers to be competing with the player on pointer
  /// events, e.g if the player is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The player will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// By default vertical and horizontal gestures are absorbed by the player.
  /// Passing an empty set will ignore the defaults.
  ///
  /// This is ignored on web.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// The background color of the [WebView].
  ///
  /// Default to [ColorScheme.background].
  final Color? backgroundColor;

  @override
  State<FullscreenYoutubePlayer> createState() {
    return _FullscreenYoutubePlayerState();
  }

  /// Launches the [FullscreenYoutubePlayer].
  ///
  /// Returns the time in seconds at which the player was popped.
  static Future<double?> launch(
    BuildContext context, {
    required String videoId,
    double? startSeconds,
    double? endSeconds,
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers =
        const <Factory<OneSequenceGestureRecognizer>>{},
    Color? backgroundColor,
  }) {
    return Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return FullscreenYoutubePlayer(
            videoId: videoId,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            gestureRecognizers: gestureRecognizers,
            backgroundColor: backgroundColor,
          );
        },
      ),
    );
  }
}

class _FullscreenYoutubePlayerState extends State<FullscreenYoutubePlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      startSeconds: widget.startSeconds,
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    )..setFullScreenListener((_) async {
        Navigator.pop(context, await _controller.currentTime);
      });

    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, await _controller.currentTime);
        return false;
      },
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: MediaQuery.of(context).size.aspectRatio,
        backgroundColor: widget.backgroundColor,
        gestureRecognizers: widget.gestureRecognizers,
      ),
    );
  }

  @override
  void dispose() {
    _resetOrientation();
    _controller.close();
    super.dispose();
  }

  void _resetOrientation() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
