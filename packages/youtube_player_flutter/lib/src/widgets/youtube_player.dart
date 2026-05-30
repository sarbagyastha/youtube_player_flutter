// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yp_iframe;

import '../controller/overlay_controller.dart';
import '../controller/overlay_controller_scope.dart';
import 'controls/controls_overlay.dart';
import 'typedefs.dart';

/// A YouTube player widget with Material 3 custom controls.
///
/// Wraps [YoutubePlayerController] from `youtube_player_iframe` and renders
/// a fully themed controls overlay instead of YouTube's native controls.
///
/// ### Minimal usage
/// ```dart
/// YoutubePlayer(
///   controller: YoutubePlayerController.fromVideoId(
///     videoId: 'dQw4w9WgXcQ',
///     autoPlay: true,
///   ),
/// )
/// ```
///
/// ### Custom controls
/// Use [Stack] to overlay controls on top of the player surface. The
/// [player] widget occupies the video area; place controls with [Positioned].
/// ```dart
/// YoutubePlayer(
///   controller: controller,
///   builder: (context, player, ctrl) => Stack(
///     children: [
///       player,
///       Positioned(bottom: 0, left: 0, right: 0, child: MyControls(controller: ctrl)),
///     ],
///   ),
/// )
/// ```
///
/// ### Theming
/// Apply [YoutubePlayerTheme] via [ThemeData.extensions] to override defaults:
/// ```dart
/// ThemeData(
///   extensions: const [YoutubePlayerTheme(progressBarActiveColor: Colors.red)],
/// )
/// ```
class YoutubePlayer extends StatefulWidget {
  const YoutubePlayer({
    super.key,
    required this.controller,
    this.aspectRatio = 16 / 9,
    this.builder,
    this.autoHideDuration = const Duration(seconds: 3),
    this.backgroundColor,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.keepAlive = false,
    this.autoFullScreen = true,
    this.enableFullScreenOnVerticalDrag = true,
  });

  /// Controls the player. Create via [YoutubePlayerController.fromVideoId]
  /// or [YoutubePlayerController]. YouTube's native controls are always hidden
  /// regardless of [YoutubePlayerParams.showControls].
  final YoutubePlayerController controller;

  /// Aspect ratio of the video surface. Defaults to 16/9.
  final double aspectRatio;

  /// Provide this to fully replace the default controls overlay.
  ///
  /// Receives the raw video surface [Widget] and the [YoutubePlayerController].
  /// The [YoutubePlayerBuilder] typedef is re-exported from this package.
  final YoutubePlayerBuilder? builder;

  /// How long controls stay visible after the last interaction before
  /// auto-hiding. Ignored when the player is paused or buffering.
  final Duration autoHideDuration;

  /// Background color shown while the player is initialising.
  /// Defaults to [ColorScheme.surface].
  final Color? backgroundColor;

  /// Gesture recognizers passed to the underlying [WebViewWidget].
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// Whether to keep the player alive when scrolled off-screen.
  final bool keepAlive;

  /// Automatically enter fullscreen when the device rotates to landscape.
  final bool autoFullScreen;

  /// Enable swiping up/down on the player to toggle fullscreen.
  final bool enableFullScreenOnVerticalDrag;

  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer>
    with AutomaticKeepAliveClientMixin {
  late final OverlayController _overlayCtrl;
  StreamSubscription<YoutubePlayerValue>? _playerStateSub;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _overlayCtrl = OverlayController(autoHideDuration: widget.autoHideDuration);
    _playerStateSub = widget.controller.stream.listen(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _overlayCtrl.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged(YoutubePlayerValue value) {
    switch (value.playerState) {
      case .playing:
        _overlayCtrl.resetTimer();
      case .paused:
      case .buffering:
      case .ended:
        _overlayCtrl.cancelTimer();
        _overlayCtrl.isVisible.value = true;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // On non-web platforms, hide YouTube's native controls so the custom
    // overlay is the only UI. On web, gesture events don't reach Flutter
    // overlays through the iframe element, so keep native controls and show
    // the native fullscreen button.
    final initParams = kIsWeb
        ? widget.controller.params.copyWith(showFullscreenButton: true)
        : widget.controller.params.copyWith(
            showControls: false,
            showFullscreenButton: false,
          );

    // On mobile, the player WebView lives inside an OverlayPortal managed by
    // iframe's YoutubePlayer. Controls must also be in that overlay so they
    // render above the WebView. On desktop and web, a simple Stack suffices.
    Widget Function(BuildContext, bool)? controlsBuilder;
    if (!kIsWeb) {
      if (_isMobile && widget.builder != null) {
        controlsBuilder = (ctx, _) => OverlayControllerScope(
          overlayController: _overlayCtrl,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _overlayCtrl.toggle,
            child: widget.builder!(
              ctx,
              const SizedBox.expand(),
              widget.controller,
            ),
          ),
        );
      } else if (widget.builder == null) {
        controlsBuilder = (ctx, _) => _DefaultControlsLayer(
          controller: widget.controller,
          overlayController: _overlayCtrl,
        );
      }
      // Non-mobile with builder: controlsBuilder stays null; builder wraps
      // the iframe player directly (see return below).
    }

    final iframePlayer = yp_iframe.YoutubePlayer(
      controller: widget.controller,
      aspectRatio: widget.aspectRatio,
      gestureRecognizers: widget.gestureRecognizers,
      backgroundColor: widget.backgroundColor,
      enableFullScreenOnVerticalDrag: widget.enableFullScreenOnVerticalDrag,
      keepAlive: _isMobile || widget.keepAlive,
      autoFullScreen: widget.autoFullScreen,
      initParams: initParams,
      controlsBuilder: controlsBuilder,
    );

    // On non-mobile with a custom builder, hand the bare iframe player to
    // the builder so the user controls the entire layout.
    if (!_isMobile && widget.builder != null) {
      return widget.builder!(context, iframePlayer, widget.controller);
    }

    return iframePlayer;
  }

  @override
  bool get wantKeepAlive => _isMobile || widget.keepAlive;
}

// ---------------------------------------------------------------------------
// Default controls layer — auto-hide overlay with horizontal seek gesture.
// ---------------------------------------------------------------------------

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
                  targetSeconds:
                      (_videoState.position.inSeconds.toDouble() +
                              _seekDeltaSeconds)
                          .clamp(
                            0.0,
                            widget.controller.metadata.duration.inSeconds
                                .toDouble(),
                          ),
                ),
              ),
          ],
        ),
      ),
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
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.all(Radius.circular(8)),
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
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
