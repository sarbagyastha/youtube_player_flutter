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

        // CompositedTransformFollower places the child at the placeholder's
        // current screen position (tracked at the render layer — smooth during
        // scroll with no setState). The AnimatedContainer then:
        //   • normal: identity transform, natural size
        //   • fullscreen: translate to (fsLeft, fsTop) by subtracting the
        //     placeholder offset (playerRect.left/top), expand to fsWidth/fsHeight.
        //
        // playerRect is only read in the non-fullscreen width/height and in the
        // fullscreen transform offset. Two-frame delay in didChangeMetrics ensures
        // playerRect is refreshed before fullscreen is triggered on rotation.
        return Stack(
          fit: StackFit.expand,
          children: [
            _FullscreenBackground(isFullscreen: isFullscreen),
            Positioned(
              top: 0,
              left: 0,
              child: CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  transform: isFullscreen
                      ? Matrix4.translationValues(
                          -playerRect.left + fsLeft,
                          -playerRect.top + fsTop,
                          0,
                        )
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

                      return hideForOther
                          ? IgnorePointer(
                              child: Opacity(opacity: 0, child: content),
                            )
                          : content;
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

class _DefaultControlsLayer extends StatelessWidget {
  const _DefaultControlsLayer({
    required this.controller,
    required this.overlayController,
  });

  final YoutubePlayerController controller;
  final OverlayController overlayController;

  @override
  Widget build(BuildContext context) {
    return OverlayControllerScope(
      overlayController: overlayController,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: overlayController.toggle,
        child: ValueListenableBuilder<bool>(
          valueListenable: overlayController.isVisible,
          builder: (context, visible, child) => AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: visible ? 1.0 : 0.0,
            child: child,
          ),
          child: ControlsOverlay(controller: controller),
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
