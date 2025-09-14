// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/src/widgets/fullscreen_youtube_player.dart';

import '../controller/youtube_player_controller.dart';

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
  });

  /// The [controller] for this player.
  final YoutubePlayerController controller;

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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late YoutubePlayerController _controller;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();
  }

  @override
  void didUpdateWidget(YoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.backgroundColor != oldWidget.backgroundColor) {
      _updateBackgroundColor(widget.backgroundColor);
    }

    // If controller changed, re-initialize
    if (widget.controller != oldWidget.controller) {
      _handleControllerChange(oldWidget.controller);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isDisposed || !_isInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
        // Pause video when app goes to background
        _controller.pauseVideo().catchError((e) {
          // Ignore errors when pausing
        });
        break;
      case AppLifecycleState.resumed:
        // No action needed on resume, let user control playback
        break;
      case AppLifecycleState.detached:
        // Clean up when app is detached
        _controller.close().catchError((e) {
          // Ignore errors during cleanup
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          color:
              widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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

  void _handleControllerChange(YoutubePlayerController oldController) {
    // Reset the old controller
    oldController.reset().catchError((e) {
      // Ignore reset errors
    });

    // Update to new controller
    _controller = widget.controller;
    _isInitialized = false;
    _initPlayer();
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
    if (defaultTargetPlatform == TargetPlatform.macOS) return;
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    _controller.webViewController.setBackgroundColor(bgColor);
  }

  Future<void> _initPlayer() async {
    if (_isDisposed) return;

    try {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) {
          _updateBackgroundColor(widget.backgroundColor);
        }
      });

      await _controller.init();

      if (!_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (!_isDisposed) {
        // Show error state or retry initialization
        setState(() {
          _isInitialized = false;
        });

        // Retry initialization after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed && !_isInitialized) {
            _initPlayer();
          }
        });
      }
    }
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
