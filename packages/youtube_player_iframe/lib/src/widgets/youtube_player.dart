// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controller/youtube_player_controller.dart';
import '../enums/player_state.dart';
import '../helpers/platform.dart';
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

    if (isMobile) {
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
    if (isMobile) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updatePlayerRect();
      if (!mounted || !widget.autoFullScreen) return;
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

    if (!isMobile) {
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
            overlayChildBuilder: (context) => _PlayerOverlayContent(
              controller: _controller,
              playerRect: _playerRect,
              backgroundColor: widget.backgroundColor,
              gestureRecognizers: widget.gestureRecognizers,
              enableFullScreenOnVerticalDrag:
                  widget.enableFullScreenOnVerticalDrag,
            ),
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _updatePlayerRect();
                  });
                  return SizedBox.expand(key: _placeholderKey);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateBackgroundColor(Color? backgroundColor) {
    if (!mounted) return;
    if (!isMobile) return;
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

class _PlayerOverlayContent extends StatelessWidget {
  const _PlayerOverlayContent({
    required this.controller,
    required this.playerRect,
    required this.backgroundColor,
    required this.gestureRecognizers,
    required this.enableFullScreenOnVerticalDrag,
  });

  final YoutubePlayerController controller;
  final Rect playerRect;
  final Color? backgroundColor;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final bool enableFullScreenOnVerticalDrag;

  @override
  Widget build(BuildContext context) {
    if (playerRect.isEmpty) return const SizedBox.shrink();
    final screenSize = MediaQuery.of(context).size;

    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        final isFullscreen = value.fullScreenOption.enabled;

        return Stack(
          fit: StackFit.expand,
          children: [
            _FullscreenBackground(isFullscreen: isFullscreen),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: isFullscreen ? 0 : playerRect.top,
              left: isFullscreen ? 0 : playerRect.left,
              width: isFullscreen ? screenSize.width : playerRect.width,
              height: isFullscreen ? screenSize.height : playerRect.height,
              child: _YoutubeWebView(
                controller: controller,
                gestureRecognizers: gestureRecognizers,
                enableFullScreenOnVerticalDrag: enableFullScreenOnVerticalDrag,
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: isFullscreen ? 0 : playerRect.top,
              left: isFullscreen ? 0 : playerRect.left,
              width: isFullscreen ? screenSize.width : playerRect.width,
              height: isFullscreen ? screenSize.height : playerRect.height,
              child: _PlayerLoadingOverlay(
                controller: controller,
                backgroundColor: backgroundColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FullscreenBackground extends StatelessWidget {
  const _FullscreenBackground({required this.isFullscreen});

  final bool isFullscreen;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isFullscreen,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isFullscreen ? 1.0 : 0.0,
        child: const ColoredBox(color: Colors.black),
      ),
    );
  }
}

class _PlayerLoadingOverlay extends StatelessWidget {
  const _PlayerLoadingOverlay({
    required this.controller,
    required this.backgroundColor,
  });

  final YoutubePlayerController controller;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.playerState != n.playerState,
      builder: (context, value) {
        final isInitializing =
            value.playerState == PlayerState.unknown ||
            value.playerState == PlayerState.unStarted;
        return IgnorePointer(
          ignoring: !isInitializing,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isInitializing ? 1.0 : 0.0,
            child: ColoredBox(
              color: backgroundColor ?? Theme.of(context).colorScheme.surface,
            ),
          ),
        );
      },
    );
  }
}

class _YoutubeWebView extends StatelessWidget {
  const _YoutubeWebView({
    required this.controller,
    required this.gestureRecognizers,
    required this.enableFullScreenOnVerticalDrag,
  });

  final YoutubePlayerController controller;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final bool enableFullScreenOnVerticalDrag;

  void _onVerticalDrag(DragUpdateDetails details) {
    final delta = details.delta.dy;
    if (delta.abs() > 10) {
      delta.isNegative
          ? controller.enterFullScreen()
          : controller.exitFullScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final webView = WebViewWidget(
      controller: controller.webViewController,
      gestureRecognizers: gestureRecognizers,
    );

    if (!enableFullScreenOnVerticalDrag) return webView;

    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDrag,
      child: webView,
    );
  }
}
