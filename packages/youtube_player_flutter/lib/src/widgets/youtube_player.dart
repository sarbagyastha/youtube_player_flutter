import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:youtube_player_iframe/webview.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../controller/overlay_controller.dart';
import '../controller/overlay_controller_scope.dart';
import 'controls/controls_overlay.dart';
import 'player_overlay_content.dart';
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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // Tracks how many YoutubePlayer instances are currently in fullscreen so
  // other players can hide their overlay content and avoid surfacing on top.
  static final _fullscreenCount = ValueNotifier<int>(0);

  // Tracks which controller was most recently active (playing/buffering).
  // Used to break the tie when multiple players are live during rotation:
  // only the last-active player auto-enters fullscreen, preventing the
  // first-registered player from stealing fullscreen from the playing one.
  static YoutubePlayerController? _lastActiveController;

  late final OverlayController _overlayCtrl;
  final _overlayPortalCtrl = OverlayPortalController();
  final _placeholderKey = GlobalKey();
  final _layerLink = LayerLink();
  Rect _playerRect = Rect.zero;
  StreamSubscription<YoutubePlayerValue>? _playerStateSub;
  bool _wasFullscreen = false;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _overlayCtrl = OverlayController(autoHideDuration: widget.autoHideDuration);
    _initPlayer();
    _playerStateSub = widget.controller.stream.listen(_onPlayerStateChanged);

    if (_isMobile) {
      WidgetsBinding.instance.addObserver(this);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _updateBackgroundColor();
        _updatePlayerRect();
        _overlayPortalCtrl.show();
      });
    }
  }

  @override
  void didUpdateWidget(YoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.backgroundColor != oldWidget.backgroundColor) {
      _updateBackgroundColor();
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _overlayCtrl.dispose();
    if (_isMobile) WidgetsBinding.instance.removeObserver(this);
    if (_wasFullscreen) {
      _fullscreenCount.value =
          (_fullscreenCount.value - 1).clamp(0, _fullscreenCount.value);
    }
    if (_lastActiveController == widget.controller) _lastActiveController = null;
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Two-phase: first let the layout settle and update playerRect, then
    // toggle fullscreen. This ensures PlayerOverlayContent never sees
    // isFullscreen=true with a stale playerRect from the previous orientation,
    // which would cause the AnimatedPositioned to animate from the wrong origin.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updatePlayerRect();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.autoFullScreen) return;
        final view = WidgetsBinding.instance.platformDispatcher.views.first;
        final size = view.physicalSize / view.devicePixelRatio;
        final isLandscape = size.width > size.height;
        final opt = widget.controller.value.fullScreenOption;
        if (isLandscape && !opt.enabled) {
          // Only enter fullscreen if this player is active AND was the most
          // recently active player. All players receive didChangeMetrics; the
          // isActive guard prevents paused players from entering, and the
          // _lastActiveController guard prevents a player that was active
          // earlier (but is now background) from stealing fullscreen from the
          // player the user is currently watching.
          final state = widget.controller.value.playerState;
          final isActive = state == PlayerState.playing ||
              state == PlayerState.buffering;
          final isLastActive = _lastActiveController == null ||
              _lastActiveController == widget.controller;
          if (isActive && isLastActive) {
            widget.controller.enterFullScreen(lock: false);
          }
        } else if (!isLandscape && opt.enabled && !opt.locked) {
          widget.controller.exitFullScreen(lock: false);
        }
      });
    });
  }

  void _onPlayerStateChanged(YoutubePlayerValue value) {
    final isNowFullscreen = value.fullScreenOption.enabled;
    if (isNowFullscreen != _wasFullscreen) {
      _wasFullscreen = isNowFullscreen;
      if (isNowFullscreen) {
        _fullscreenCount.value++;
      } else {
        _fullscreenCount.value =
            (_fullscreenCount.value - 1).clamp(0, _fullscreenCount.value);
      }
    }

    switch (value.playerState) {
      case PlayerState.playing:
        _lastActiveController = widget.controller;
        _overlayCtrl.resetTimer();
      case PlayerState.paused:
      case PlayerState.buffering:
      case PlayerState.ended:
        _overlayCtrl.cancelTimer();
        _overlayCtrl.isVisible.value = true;
      default:
        break;
    }
  }

  void _updatePlayerRect() {
    final box =
        _placeholderKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    // localToGlobal can return non-finite values when the render object is
    // kept alive but outside the layout viewport. Ignore those frames.
    if (!offset.dx.isFinite ||
        !offset.dy.isFinite ||
        !size.width.isFinite ||
        !size.height.isFinite ||
        size.isEmpty) {
      return;
    }
    final newRect = offset & size;
    if (newRect != _playerRect) setState(() => _playerRect = newRect);
  }

  void _updateBackgroundColor() {
    if (!mounted) return;
    final color =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    widget.controller.webViewController.setBackgroundColor(color);
  }

  Future<void> _initPlayer() async {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateBackgroundColor();
    });

    // On web, let YouTube's native iframe controls handle interaction (gesture
    // events don't propagate through the iframe element on web, so custom
    // Flutter overlays are unusable). On other platforms, force-hide native
    // controls so our overlay is the only UI.
    final params = kIsWeb
        ? widget.controller.params
        : widget.controller.params.copyWith(
            showControls: false,
            showFullscreenButton: false,
          );
    await widget.controller.initWithParams(params: params);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isMobile) {
      return _buildNonMobile(context);
    }

    return YoutubeValueBuilder(
      controller: widget.controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        return PopScope(
          canPop: !value.fullScreenOption.enabled,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && value.fullScreenOption.enabled) {
              widget.controller.exitFullScreen();
            }
          },
          child: OverlayPortal(
            controller: _overlayPortalCtrl,
            overlayChildBuilder: (_) => PlayerOverlayContent(
              controller: widget.controller,
              playerRect: _playerRect,
              layerLink: _layerLink,
              overlayController: _overlayCtrl,
              backgroundColor: widget.backgroundColor,
              gestureRecognizers: widget.gestureRecognizers,
              enableFullScreenOnVerticalDrag:
                  widget.enableFullScreenOnVerticalDrag,
              builder: widget.builder,
              aspectRatio: widget.aspectRatio,
              fullscreenCount: _fullscreenCount,
            ),
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: LayoutBuilder(
                builder: (context, _) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _updatePlayerRect();
                  });
                  return CompositedTransformTarget(
                    link: _layerLink,
                    child: SizedBox.expand(key: _placeholderKey),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNonMobile(BuildContext context) {
    final webView = WebViewWidget(
      controller: widget.controller.webViewController,
      gestureRecognizers: widget.gestureRecognizers,
    );

    // On web, gesture events don't reach Flutter overlays through the iframe.
    // Render the bare WebView so users interact with YouTube's native controls.
    if (kIsWeb) {
      if (widget.builder != null) {
        return AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: widget.builder!(
            context,
            AspectRatio(aspectRatio: widget.aspectRatio, child: webView),
            widget.controller,
          ),
        );
      }
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: webView,
      );
    }

    if (widget.builder != null) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: widget.builder!(
          context,
          AspectRatio(aspectRatio: widget.aspectRatio, child: webView),
          widget.controller,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        children: [
          Positioned.fill(child: webView),
          Positioned.fill(
            child: OverlayControllerScope(
              overlayController: _overlayCtrl,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _overlayCtrl.toggle,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _overlayCtrl.isVisible,
                  builder: (context, visible, child) => AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: visible ? 1.0 : 0.0,
                    child: child,
                  ),
                  child: ControlsOverlay(controller: widget.controller),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // On mobile the WebView lives inside OverlayPortal, which is owned by this
  // state. If the state is disposed (keepAlive:false, widget recycled by the
  // list), OverlayPortal is removed and WebViewWidget is torn down. When the
  // placeholder re-enters the list a new state calls _initPlayer() →
  // loadHtmlString(), which reloads the entire YouTube IFrame and causes an
  // error. Always keep alive on mobile so the overlay/WebView is never torn
  // down while the controller is still live.
  @override
  bool get wantKeepAlive => _isMobile || widget.keepAlive;
}
