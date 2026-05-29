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
/// Positions the [WebViewWidget] at [playerRect] (animating to full-screen
/// when [fullScreenOption.enabled] is true) and overlays the controls on top.
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
  /// Shared counter of how many players are currently in fullscreen.
  /// When non-zero and this player is not fullscreen, its overlay layers are
  /// hidden so they don't surface above the fullscreen player's background.
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
    // Guard NaN: Rect.isEmpty returns false for NaN dimensions because
    // NaN comparisons are always false, so check isFinite explicitly.
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

        // In portrait fullscreen, constrain to the aspect ratio and center
        // vertically so the video is not stretched to fill the full screen.
        final isPortrait = screenSize.width < screenSize.height;
        final double fsWidth;
        final double fsHeight;
        final double fsOffsetY;
        if (isFullscreen && isPortrait) {
          fsWidth = screenSize.width;
          fsHeight = screenSize.width / aspectRatio;
          fsOffsetY = (screenSize.height - fsHeight) / 2;
        } else {
          fsWidth = screenSize.width;
          fsHeight = screenSize.height;
          fsOffsetY = 0;
        }

        // Always use CompositedTransformFollower so the widget element is
        // never recreated when fullscreen toggles — this preserves the
        // AnimatedContainer's animation state for the slide transition.
        // In normal mode: follower tracks the placeholder, no transform.
        // In fullscreen: AnimatedContainer shifts by (-rect.left, -rect.top)
        // to cancel the follower's offset, landing the content at (0, 0),
        // and expands to screen size — the same path AnimatedPositioned took.
        Widget positionedLayer(Widget child) {
          return Positioned(
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
                        -playerRect.left,
                        -playerRect.top + fsOffsetY,
                        0,
                      )
                    : Matrix4.identity(),
                width: isFullscreen ? fsWidth : playerRect.width,
                height: isFullscreen ? fsHeight : playerRect.height,
                child: child,
              ),
            ),
          );
        }

        return ValueListenableBuilder<int>(
          valueListenable: fullscreenCount,
          builder: (context, count, _) {
            // Hide this player's layers when another player owns the
            // fullscreen — the other player's OverlayPortal entry is higher
            // in z-order so without hiding it would surface above the
            // fullscreen background. Opacity+IgnorePointer keeps the WebView
            // alive (no reload on exit) while making it invisible.
            final hideForOther = !isFullscreen && count > 0;

            // Wrap content (not the Positioned itself) so Positioned stays a
            // direct Stack child — required by Flutter's parent-data protocol.
            Widget maybeHide(Widget w) => hideForOther
                ? IgnorePointer(child: Opacity(opacity: 0, child: w))
                : w;

            return Stack(
              fit: StackFit.expand,
              children: [
                _FullscreenBackground(isFullscreen: isFullscreen),

                positionedLayer(maybeHide(
                  GestureDetector(
                    onVerticalDragUpdate: enableFullScreenOnVerticalDrag
                        ? _onVerticalDrag
                        : null,
                    child: WebViewWidget(
                      controller: controller.webViewController,
                      gestureRecognizers: gestureRecognizers,
                    ),
                  ),
                )),

                positionedLayer(maybeHide(
                  builder != null
                      ? builder!(
                          context,
                          SizedBox(
                            width: isFullscreen ? fsWidth : playerRect.width,
                            height: isFullscreen ? fsHeight : playerRect.height,
                          ),
                          controller,
                        )
                      : _DefaultControlsLayer(
                          controller: controller,
                          overlayController: overlayController,
                        ),
                )),

                positionedLayer(maybeHide(
                  _LoadingOverlay(
                    controller: controller,
                    backgroundColor: backgroundColor,
                  ),
                )),
              ],
            );
          },
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
