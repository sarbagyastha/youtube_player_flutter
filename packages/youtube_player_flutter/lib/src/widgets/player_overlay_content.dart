import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  });

  final YoutubePlayerController controller;
  final Rect playerRect;
  final LayerLink layerLink;
  final OverlayController overlayController;
  final Color? backgroundColor;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final bool enableFullScreenOnVerticalDrag;
  final YoutubePlayerBuilder? builder;

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
    if (playerRect.isEmpty) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;

    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        final isFullscreen = value.fullScreenOption.enabled;

        final fsWidth = screenSize.width;
        final fsHeight = screenSize.height;
        final normalWidth = playerRect.width;
        final normalHeight = playerRect.height;

        Widget positionedLayer(Widget child) {
          if (isFullscreen) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 0,
              left: 0,
              width: fsWidth,
              height: fsHeight,
              child: child,
            );
          }
          // CompositedTransformFollower tracks the placeholder's position
          // every frame through the layer tree — no scroll lag.
          return Positioned(
            top: 0,
            left: 0,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              child: SizedBox(
                width: normalWidth,
                height: normalHeight,
                child: child,
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            _FullscreenBackground(isFullscreen: isFullscreen),

            positionedLayer(
              GestureDetector(
                onVerticalDragUpdate: enableFullScreenOnVerticalDrag
                    ? _onVerticalDrag
                    : null,
                child: WebViewWidget(
                  controller: controller.webViewController,
                  gestureRecognizers: gestureRecognizers,
                ),
              ),
            ),

            positionedLayer(
              builder != null
                  ? builder!(
                      context,
                      SizedBox(
                        width: isFullscreen ? fsWidth : normalWidth,
                        height: isFullscreen ? fsHeight : normalHeight,
                      ),
                      controller,
                    )
                  : _DefaultControlsLayer(
                      controller: controller,
                      overlayController: overlayController,
                    ),
            ),

            positionedLayer(
              _LoadingOverlay(
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
