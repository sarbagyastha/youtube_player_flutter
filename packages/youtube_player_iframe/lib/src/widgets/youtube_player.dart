// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controller/youtube_player_controller.dart';
import '../helpers/youtube_value_builder.dart';

/// A widget to play or stream Youtube Videos.
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
    this.autoFullScreen = true,
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

  /// Whether to automatically enter fullscreen when the device rotates to landscape.
  ///
  /// Default is true.
  final bool autoFullScreen;

  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late final YoutubePlayerController _controller;

  final _overlayController = OverlayPortalController();
  final _placeholderKey = GlobalKey();
  Rect _playerRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _initPlayer();

    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _updatePlayerRect();
        _overlayController.show();
      });
    }
  }

  @override
  void didUpdateWidget(YoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.backgroundColor != oldWidget.backgroundColor) {
      _updateBackgroundColor(widget.backgroundColor);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!widget.autoFullScreen) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updatePlayerRect();
      if (!mounted) return;
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      final isLandscape = size.width > size.height;
      final opt = _controller.value.fullScreenOption;

      if (isLandscape && !opt.enabled) {
        _controller.enterFullScreen(lock: false);
      } else if (!isLandscape && opt.enabled && !opt.locked) {
        _controller.exitFullScreen(lock: false);
      }
    });
  }

  void _updatePlayerRect() {
    final box =
        _placeholderKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final newRect = box.localToGlobal(Offset.zero) & box.size;
    if (newRect != _playerRect) setState(() => _playerRect = newRect);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (kIsWeb) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: WebViewWidget(
          controller: _controller.webViewController,
          gestureRecognizers: widget.gestureRecognizers,
        ),
      );
    }

    return YoutubeValueBuilder(
      controller: _controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        return PopScope(
          canPop: !value.fullScreenOption.enabled,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && value.fullScreenOption.enabled) {
              _controller.exitFullScreen();
            }
          },
          child: OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: _buildOverlayContent,
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: SizedBox.expand(key: _placeholderKey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    if (_playerRect.isEmpty) return const SizedBox.shrink();
    final screenSize = MediaQuery.of(context).size;

    return YoutubeValueBuilder(
      controller: _controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        final isFullscreen = value.fullScreenOption.enabled;

        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              ignoring: !isFullscreen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isFullscreen ? 1.0 : 0.0,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: isFullscreen ? 0 : _playerRect.top,
              left: isFullscreen ? 0 : _playerRect.left,
              width: isFullscreen ? screenSize.width : _playerRect.width,
              height: isFullscreen ? screenSize.height : _playerRect.height,
              child: _buildWebView(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebView() {
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

    return player;
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
    if (!mounted) return;
    if (defaultTargetPlatform == TargetPlatform.macOS) return;
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
