import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/webview.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../controller/overlay_controller.dart';
import '../controller/overlay_controller_scope.dart';
import 'controls/controls_overlay.dart';
import 'typedefs.dart';

/// The content rendered inside the [OverlayPortal] on mobile.
///
/// [CompositedTransformFollower] tracks the placeholder's scroll position at
/// the render layer (smooth, no setState). In fullscreen the transform is
/// computed from [screenSize] only — no [playerRect] dependency — so rotation
/// while fullscreen is always correct.
class PlayerOverlayContent extends StatelessWidget {
  const PlayerOverlayContent({
    super.key,
    required this.controller,
    required this.playerRect,
    required this.layerLink,
    required this.overlayController,
    required this.backgroundColor,
    required this.gestureRecognizers,
    required this.enableFullScreenOnVerticalDrag,
    required this.builder,
    required this.fullscreenCount,
    this.aspectRatio = 16 / 9,
  });

  final YoutubePlayerController controller;
  final Rect playerRect;
  final LayerLink layerLink;
  final OverlayController overlayController;
  final Color? backgroundColor;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final bool enableFullScreenOnVerticalDrag;
  final YoutubePlayerBuilder? builder;
  final double aspectRatio;

  /// Tracks how many players are currently in fullscreen.
  /// When non-zero and this player is not fullscreen, its overlay is hidden
  /// so it doesn't surface above another player's fullscreen background.
  final ValueListenable<int> fullscreenCount;

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
    if (!playerRect.width.isFinite ||
        !playerRect.height.isFinite ||
        playerRect.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;

    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        final isFullscreen = value.fullScreenOption.enabled;

        // Fullscreen target bounds — always fill the full screen so both the
        // video and controls cover the entire display. YouTube handles its own
        // aspect ratio internally inside the WebView.
        // Derived from screenSize only (no playerRect) so rotation while
        // fullscreen is always correct.
        const double fsLeft = 0, fsTop = 0;
        final double fsWidth = screenSize.width;
        final double fsHeight = screenSize.height;

        // Whether the placeholder is within the visible viewport. When it is,
        // CompositedTransformTarget paints its LeaderLayer and the follower is
        // "linked" — it places the child at the placeholder's screen position.
        // When off-screen (e.g. second player scrolled below the fold in
        // landscape), the SliverList doesn't paint the placeholder so the
        // LeaderLayer is absent and the follower is "unlinked".
        final screenRect = Offset.zero & screenSize;
        final isOnScreen = playerRect.overlaps(screenRect);

        // CompositedTransformFollower places the child at the placeholder's
        // current screen position (tracked at the render layer — smooth during
        // scroll with no setState). The AnimatedContainer then:
        //   • normal: identity transform, natural size
        //   • fullscreen + on-screen: translate to (fsLeft, fsTop) by
        //     subtracting the placeholder offset (playerRect.left/top), expand
        //     to fsWidth/fsHeight.
        //   • fullscreen + off-screen: follower is unlinked; showWhenUnlinked
        //     places the child at its own layout origin (0,0), so identity
        //     transform is correct. showWhenUnlinked is true only when
        //     fullscreen so the child is never shown at a wrong position while
        //     the player is scrolled off-screen in normal mode.
        return Stack(
          fit: StackFit.expand,
          children: [
            _FullscreenBackground(isFullscreen: isFullscreen),
            Positioned(
              top: 0,
              left: 0,
              child: CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: isFullscreen,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  transform: isFullscreen
                      ? (isOnScreen
                          ? Matrix4.translationValues(
                              -playerRect.left + fsLeft,
                              -playerRect.top + fsTop,
                              0,
                            )
                          : Matrix4.identity())
                      : Matrix4.identity(),
                  width: isFullscreen ? fsWidth : playerRect.width,
                  height: isFullscreen ? fsHeight : playerRect.height,
                  child: ValueListenableBuilder<int>(
                    valueListenable: fullscreenCount,
                    builder: (context, count, _) {
                      final hideForOther = !isFullscreen && count > 0;

                      final content = Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              onVerticalDragUpdate:
                                  enableFullScreenOnVerticalDrag
                                      ? _onVerticalDrag
                                      : null,
                              child: WebViewWidget(
                                controller: controller.webViewController,
                                gestureRecognizers: gestureRecognizers,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: builder != null
                                ? OverlayControllerScope(
                                    overlayController: overlayController,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: overlayController.toggle,
                                      child: builder!(
                                        context,
                                        SizedBox(
                                          width: isFullscreen
                                              ? fsWidth
                                              : playerRect.width,
                                          height: isFullscreen
                                              ? fsHeight
                                              : playerRect.height,
                                        ),
                                        controller,
                                      ),
                                    ),
                                  )
                                : _DefaultControlsLayer(
                                    controller: controller,
                                    overlayController: overlayController,
                                  ),
                          ),
                          Positioned.fill(
                            child: _LoadingOverlay(
                              controller: controller,
                              backgroundColor: backgroundColor,
                            ),
                          ),
                        ],
                      );

                      // Offstage removes the WebView from Flutter's compositing
                      // pipeline entirely — the platform view texture is not
                      // rendered, so it cannot bleed through another player's
                      // fullscreen overlay regardless of overlay z-order.
                      // Opacity(opacity:0) is insufficient because Android
                      // platform views render in a native surface layer that is
                      // independent of Flutter's opacity compositing.
                      // Using a stable Offstage wrapper (rather than
                      // conditionally wrapping) prevents the WebView from being
                      // torn down and recreated when hideForOther toggles.
                      return Offstage(offstage: hideForOther, child: content);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DefaultControlsLayer extends StatefulWidget {
  const _DefaultControlsLayer({
    required this.controller,
    required this.overlayController,
  });

  final YoutubePlayerController controller;
  final OverlayController overlayController;

  @override
  State<_DefaultControlsLayer> createState() => _DefaultControlsLayerState();
}

class _DefaultControlsLayerState extends State<_DefaultControlsLayer> {
  late StreamSubscription<YoutubeVideoState> _subscription;
  YoutubeVideoState _videoState = const YoutubeVideoState();
  bool _isSeeking = false;
  double _seekDeltaSeconds = 0;
  double _dragStartX = 0;

  // Full player-width drag = 120 s of seek (VLC-like fixed physical feel).
  static const double _seekWidthRatio = 120.0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.videoStateStream.listen((state) {
      if (mounted && !_isSeeking) setState(() => _videoState = state);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (widget.controller.metadata.duration == Duration.zero) return;
    _dragStartX = details.localPosition.dx;
    widget.overlayController.cancelTimer();
    setState(() {
      _isSeeking = true;
      _seekDeltaSeconds = 0;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isSeeking) return;
    final playerWidth = context.size?.width ?? 1;
    final dx = details.localPosition.dx - _dragStartX;
    setState(() => _seekDeltaSeconds = (dx / playerWidth) * _seekWidthRatio);
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    if (!_isSeeking) return;
    final duration = widget.controller.metadata.duration.inSeconds.toDouble();
    final currentPos = _videoState.position.inSeconds.toDouble();
    final newPos = (currentPos + _seekDeltaSeconds).clamp(0.0, duration);
    widget.controller.seekTo(seconds: newPos, allowSeekAhead: true);
    widget.overlayController.resetTimer();
    setState(() {
      _isSeeking = false;
      _seekDeltaSeconds = 0;
    });
  }

  void _onHorizontalDragCancel() {
    if (!_isSeeking) return;
    widget.overlayController.resetTimer();
    setState(() {
      _isSeeking = false;
      _seekDeltaSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlayControllerScope(
      overlayController: widget.overlayController,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.overlayController.toggle,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onHorizontalDragCancel: _onHorizontalDragCancel,
        child: Stack(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: widget.overlayController.isVisible,
              builder: (context, visible, child) => AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: visible ? 1.0 : 0.0,
                child: child,
              ),
              child: ControlsOverlay(controller: widget.controller),
            ),
            if (_isSeeking)
              Center(
                child: _SeekIndicator(
                  deltaSeconds: _seekDeltaSeconds,
                  targetSeconds: (_videoState.position.inSeconds.toDouble() +
                          _seekDeltaSeconds)
                      .clamp(
                    0.0,
                    widget.controller.metadata.duration.inSeconds.toDouble(),
                  ),
                ),
              ),
          ],
        ),
      ),
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

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({
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
        final isInitializing = value.playerState == PlayerState.unknown ||
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

class _SeekIndicator extends StatelessWidget {
  const _SeekIndicator({
    required this.deltaSeconds,
    required this.targetSeconds,
  });

  final double deltaSeconds;
  final double targetSeconds;

  String _formatDelta() {
    final abs = deltaSeconds.abs().round();
    final sign = deltaSeconds >= 0 ? '+' : '-';
    final m = abs ~/ 60;
    final s = abs % 60;
    return m > 0 ? '$sign$m:${s.toString().padLeft(2, '0')}' : '$sign${s}s';
  }

  String _formatTarget() {
    final total = targetSeconds.round();
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            deltaSeconds >= 0 ? Icons.fast_forward : Icons.fast_rewind,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _formatDelta(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '(${_formatTarget()})',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
