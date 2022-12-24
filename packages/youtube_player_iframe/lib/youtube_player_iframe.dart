// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'youtube_player_iframe.dart';

export 'package:youtube_player_iframe/src/controller/youtube_player_controller.dart';
export 'package:youtube_player_iframe/src/iframe_api/youtube_player_iframe_api.dart';

export 'src/enums/playback_rate.dart';
export 'src/enums/player_state.dart';
export 'src/enums/thumbnail_quality.dart';
export 'src/enums/youtube_error.dart';
export 'src/helpers/youtube_value_builder.dart';
export 'src/helpers/youtube_value_provider.dart';
export 'src/meta_data.dart';
export 'src/player_params.dart';
export 'src/youtube_player_scaffold.dart';

/// A widget to play or stream Youtube Videos.
@Deprecated('Use YoutubePlayer instead')
typedef YoutubePlayerIFrame = YoutubePlayer;

/// A widget to play or stream Youtube Videos.
class YoutubePlayer extends StatefulWidget {
  /// A widget to play or stream Youtube Videos.
  const YoutubePlayer({
    super.key,
    this.controller,
    this.aspectRatio = 16 / 9,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.backgroundColor,
    this.userAgent,
    this.enableFullScreenOnVerticalDrag = true,
  });

  /// The [controller] for this player.
  final YoutubePlayerController? controller;

  /// Aspect ratio for the player.
  final double aspectRatio;

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
  final Color? backgroundColor;

  /// The value used for the HTTP User-Agent: request header.
  ///
  /// When null the platform's webview default is used for the User-Agent header.
  ///
  /// By default `userAgent` is null.
  final String? userAgent;

  /// Enables switching full screen mode on vertical drag in the player.
  ///
  /// Default is true.
  final bool enableFullScreenOnVerticalDrag;

  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? YoutubePlayerController();
  }

  @override
  Widget build(BuildContext context) {
    Widget player = WebViewWidget(
      controller: _controller.webViewController,
      gestureRecognizers: widget.gestureRecognizers,
    );

    if (widget.enableFullScreenOnVerticalDrag) {
      player = GestureDetector(
        onVerticalDragUpdate: _fullscreenGesture,
        child: player,
      );
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        return AspectRatio(
          aspectRatio: orientation == Orientation.landscape
              ? MediaQuery.of(context).size.aspectRatio
              : widget.aspectRatio,
          child: player,
        );
      },
    );
  }

  void _fullscreenGesture(DragUpdateDetails details) {
    final delta = details.delta.dy;

    if (delta.abs() > 10) {
      delta.isNegative
          ? _controller.enterFullScreen()
          : _controller.exitFullScreen();
    }
  }
}
