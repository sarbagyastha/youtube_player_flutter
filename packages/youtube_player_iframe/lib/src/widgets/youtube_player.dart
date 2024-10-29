// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// A widget to play or stream Youtube Videos.
///
/// See also:
///
///  * [FullscreenYoutubePlayer], which play or stream Youtube Videos in fullscreen mode.
class YoutubePlayer extends StatefulWidget {
  /// A widget to play or stream Youtube Videos.
  const YoutubePlayer({
    super.key,
    required this.controller,
    this.aspectRatio = 16 / 9,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.backgroundColor,
    @Deprecated('Unused parameter. Use `YoutubePlayerParam.userAgent` instead.')
    this.userAgent,
    this.enableFullScreenOnVerticalDrag = true,
    this.keepAlive = false,
    this.thumbnail,
  });

  /// The [controller] for this player.
  final YoutubePlayerController controller;

  /// Aspect ratio for the player.
  final double aspectRatio;

  /// Thumbnail widget to show when the player has not been playing.
  final Widget? thumbnail;

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
  /// Default to [ColorScheme.surface].
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

  /// Whether to keep the state of the player alive when it is not visible.
  final bool keepAlive;

  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer>
    with AutomaticKeepAliveClientMixin {
  late final YoutubePlayerController _controller;
  StreamSubscription<YoutubePlayerValue>? _sub;
  bool _showThumbnail = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _sub = _controller.stream.listen((value) {
      if (value.playerState == PlayerState.playing ||
          value.playerState == PlayerState.cued) {
        setState(() {
          _showThumbnail = false;
        });
      }
    });

    _initPlayer();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(YoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.backgroundColor != oldWidget.backgroundColor) {
      _updateBackgroundColor(widget.backgroundColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Widget player = Stack(
      children: [
        WebViewWidget(
          controller: _controller.webViewController,
          gestureRecognizers: widget.gestureRecognizers,
        ),
        if (widget.thumbnail != null)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _showThumbnail ? 1 : 0,
            child: widget.thumbnail!,
          ),
      ],
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
            child: player);
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

  void _updateBackgroundColor(Color? backgroundColor) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    _controller.webViewController.setBackgroundColor(bgColor);
  }

  Future<void> _initPlayer() async {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateBackgroundColor(widget.backgroundColor);
    });

    await _controller.init();
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
