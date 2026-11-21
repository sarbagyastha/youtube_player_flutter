// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart' hide YoutubePlayer;
import 'package:youtube_player/youtube_player.dart' as yp show YoutubePlayer;

import '../controller/overlay_controller.dart';
import '../controller/overlay_controller_scope.dart';
import '../fullscreen/fullscreen.dart';
import 'controls/controls_overlay.dart';
import 'typedefs.dart';

/// A YouTube player widget with YouTube-styled custom controls.
///
/// Plays through `youtube_player` with YouTube's own controls turned off, and
/// draws a themed controls overlay in Flutter instead.
///
/// On the web the player keeps YouTube's own controls and fullscreen button,
/// and fullscreen is the browser's: the iframe receives pointer input there,
/// and browser fullscreen shows only the iframe, so Flutter controls could
/// not be used in it.
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
/// `player` widget occupies the video area; place controls with [Positioned].
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
/// ### Fullscreen
/// Fullscreen is presented by Flutter, so the controls stay visible. Control
/// it from below the player with [YoutubeFullScreen.of], or use the default
/// [FullscreenButton]. On the web both use the browser's fullscreen.
///
/// ### Theming
/// Apply [YoutubePlayerTheme] via [ThemeData.extensions] to override defaults:
/// ```dart
/// ThemeData(
///   extensions: const [YoutubePlayerTheme(progressBarActiveColor: Colors.red)],
/// )
/// ```
class const YoutubePlayer({
  super.key,

  /// Controls the player. Create via [YoutubePlayerController.fromVideoId]
  /// or [YoutubePlayerController]. YouTube's native controls are hidden,
  /// regardless of [YoutubePlayerParams.showControls], except on the web.
  required final YoutubePlayerController controller,

  /// Aspect ratio of the video surface. Defaults to 16/9.
  final double aspectRatio = 16 / 9,

  /// Provide this to fully replace the default controls overlay.
  ///
  /// Receives the video surface [Widget] and the [YoutubePlayerController].
  /// It is built inline and again in fullscreen, where `player` fills the
  /// screen, so lay controls over it with a [Stack].
  /// [YoutubeFullScreen.of] works inside it.
  ///
  /// On the web, `player` shows YouTube's own controls and takes pointer
  /// input itself, so place your controls beside it rather than over it.
  final YoutubePlayerBuilder? builder,

  /// How long controls stay visible after the last interaction before
  /// auto-hiding. Ignored when the player is paused or buffering.
  final Duration autoHideDuration = const Duration(seconds: 3),

  /// Background color shown while the player is initialising.
  /// Defaults to [ColorScheme.surface].
  final Color? backgroundColor,

  /// Gestures the player should win over its ancestors.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers =
      const {},

  /// Whether to keep the player alive when scrolled off-screen.
  final bool keepAlive = false,

  /// Defers `fromVideoId(autoPlay: true)` until at least half of the player
  /// is visible, and lets only one player autoplay at a time, as required by
  /// YouTube's Required Minimum Functionality.
  final bool autoPlayWhenVisible = true,

  /// On Android and iOS, enter fullscreen when the device rotates to
  /// landscape and leave it when rotated back. Only the most recently played
  /// player reacts.
  final bool autoFullScreen = true,

  /// Swipe up on the player to enter fullscreen and down to leave it.
  ///
  /// Inline, this is off while the player is inside a [Scrollable] so that
  /// vertical drags keep scrolling it.
  final bool enableFullScreenOnVerticalDrag = true,

  /// Called when the player enters (`true`) or leaves (`false`) fullscreen.
  final ValueChanged<bool>? onFullScreenChanged,
}) extends StatefulWidget {
  /// Creates a player with YouTube-styled Flutter controls.
  this;

  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer>
    with AutomaticKeepAliveClientMixin {
  /// The player that most recently started playing; the only one that
  /// reacts to rotation when several are on screen.
  static _YoutubePlayerState? _active;

  late final _overlayCtrl = OverlayController(
    autoHideDuration: widget.autoHideDuration,
  );
  late final _fullScreen = FullScreenNotifier(
    onEnter: _enterFullScreen,
    onExit: _exitFullScreen,
  );

  /// Moves the one `yp.YoutubePlayer` element between the inline slot and
  /// the fullscreen route, so its platform view keeps its id: no native view
  /// is created and nothing reloads.
  final _playerKey = GlobalKey();

  /// Moves the whole slot, including a custom [YoutubePlayer.builder]'s
  /// controls, with the player, so their state survives fullscreen changes.
  final _slotKey = GlobalKey();

  FullScreenRoute? _route;
  StreamSubscription<YoutubePlayerValue>? _valueSub;
  PlayerState _lastPlayerState = .unknown;
  Orientation? _orientation;

  /// The controls widget, cached so the per-value rebuilds of
  /// `controlsBuilder` short-circuit on an identical widget.
  Widget? _controls;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    _valueSub = widget.controller.stream.listen(_onPlayerValue);
  }

  @override
  void didUpdateWidget(YoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _valueSub?.cancel();
      _valueSub = widget.controller.stream.listen(_onPlayerValue);
      _lastPlayerState = .unknown;
    }
    if (oldWidget.controller != widget.controller ||
        (oldWidget.builder == null) != (widget.builder == null) ||
        oldWidget.enableFullScreenOnVerticalDrag !=
            widget.enableFullScreenOnVerticalDrag) {
      _controls = null;
    }
    if (oldWidget.keepAlive != widget.keepAlive) updateKeepAlive();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.orientationOf(context);
    final previous = _orientation;
    _orientation = orientation;
    if (previous == null ||
        previous == orientation ||
        !widget.autoFullScreen ||
        !isMobilePlatform) {
      return;
    }
    // Route changes are not allowed mid-build.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _orientation != orientation) return;
      if (orientation == .landscape) {
        if (_active == null || _active == this) _fullScreen.enter(lock: false);
      } else if (!_fullScreen.isLocked) {
        _fullScreen.exit();
      }
    });
  }

  void _onPlayerValue(YoutubePlayerValue value) {
    if (kIsWeb && value.isFullScreen != _fullScreen.value) {
      // The browser owns fullscreen on the web; mirror it.
      _fullScreen
        ..isLocked = value.isFullScreen
        ..value = value.isFullScreen;
      widget.onFullScreenChanged?.call(value.isFullScreen);
    }
    final state = value.playerState;
    switch (state) {
      case .playing:
        // Only on entering playback, so other value changes while playing
        // (quality, volume, ...) don't keep postponing the auto-hide.
        if (_lastPlayerState != .playing) {
          _active = this;
          _overlayCtrl.resetTimer();
        }
      case .paused || .buffering || .ended:
        _overlayCtrl.cancelTimer();
        _overlayCtrl.isVisible.value = true;
      default:
        break;
    }
    _lastPlayerState = state;
  }

  // MARK: Fullscreen

  void _enterFullScreen({required bool lock}) {
    if (kIsWeb) {
      // Needs a user gesture; state follows through _onPlayerValue.
      unawaited(widget.controller.enterFullScreen());
      return;
    }
    final route = _route = FullScreenRoute(builder: _buildFullScreenPage);
    _fullScreen.value = true;
    applyFullScreenSystemUi(
      lock: lock,
      orientation: widget.controller.params.fullscreenOrientation,
    );
    // Covers the system back button / gesture as well as exit().
    route.popped.whenComplete(() {
      if (identical(_route, route)) _onFullScreenExited();
    });
    Navigator.of(context, rootNavigator: true).push(route);
    widget.onFullScreenChanged?.call(true);
  }

  void _exitFullScreen() {
    if (kIsWeb) return widget.controller.exitFullScreen();
    final route = _route;
    _onFullScreenExited();
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  void _onFullScreenExited() {
    if (_route == null) return;
    _route = null;
    // Flipping the notifier moves the player back inline in the same frame
    // the route is removed; the route shows black meanwhile.
    _fullScreen
      ..isLocked = false
      ..value = false;
    restoreSystemUi();
    if (mounted) widget.onFullScreenChanged?.call(false);
  }

  Widget _buildFullScreenPage(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenRatio = size.isEmpty
        ? widget.aspectRatio
        : size.width / size.height;
    // A Material (not a bare ColoredBox), so Material widgets in custom
    // builders/controls (Slider, InkWell, ...) and text styling keep working
    // once the player moves into this route, which has no Scaffold.
    return Material(
      color: Colors.black,
      child: ValueListenableBuilder<bool>(
        valueListenable: _fullScreen,
        builder: (context, isFullScreen, _) => isFullScreen
            // The player box fills the screen so the controls cover it all;
            // the iframe letterboxes the video itself.
            ? _buildSlot(context, aspectRatio: screenRatio)
            : const SizedBox.expand(),
      ),
    );
  }

  // MARK: Build

  Widget _buildControls(BuildContext context, YoutubePlayerValue value) =>
      _controls ??= _ControlsLayer(
        controller: widget.controller,
        overlayController: _overlayCtrl,
        showDefaultControls: widget.builder == null,
        enableVerticalDrag: widget.enableFullScreenOnVerticalDrag,
      );

  Widget _buildSlot(BuildContext context, {required double aspectRatio}) {
    final player = yp.YoutubePlayer(
      key: _playerKey,
      controller: widget.controller,
      aspectRatio: aspectRatio,
      gestureRecognizers: widget.gestureRecognizers,
      backgroundColor:
          widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
      keepAlive: widget.keepAlive,
      autoPlayWhenVisible: widget.autoPlayWhenVisible,
      // On the web, YouTube's own controls and fullscreen button.
      controlsBuilder: kIsWeb ? null : _buildControls,
    );
    return KeyedSubtree(
      key: _slotKey,
      child: YoutubeFullScreen(
        notifier: _fullScreen,
        child: OverlayControllerScope(
          overlayController: _overlayCtrl,
          child: switch (widget.builder) {
            final builder? => Builder(
              builder: (context) => builder(context, player, widget.controller),
            ),
            null => player,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<bool>(
      valueListenable: _fullScreen,
      // On the web the player stays in place; the browser presents it.
      builder: (context, isFullScreen, _) => isFullScreen && !kIsWeb
          // Keeps the page layout; hidden under the opaque route.
          ? AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: const SizedBox.expand(),
            )
          : _buildSlot(context, aspectRatio: widget.aspectRatio),
    );
  }

  @override
  void dispose() {
    _valueSub?.cancel();
    if (_active == this) _active = null;
    final route = _route;
    if (route == null) {
      _fullScreen.dispose();
      _overlayCtrl.dispose();
    } else {
      // The route still hosts the player; the navigator cannot change during
      // finalization, so remove it once this frame is done.
      _route = null;
      restoreSystemUi();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _fullScreen.dispose();
          _overlayCtrl.dispose();
        });
      });
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Controls layer: receives all input over the player (the iframe ignores
// pointer events while controlsBuilder is set). Shows the default controls,
// or stays transparent under a custom builder.
// ---------------------------------------------------------------------------

class const _ControlsLayer({
  required final YoutubePlayerController controller,
  required final OverlayController overlayController,
  required final bool showDefaultControls,
  required final bool enableVerticalDrag,
}) extends StatefulWidget {
  @override
  State<_ControlsLayer> createState() => _ControlsLayerState();
}

class _ControlsLayerState extends State<_ControlsLayer> {
  /// Seek offset in seconds while dragging horizontally, else `null`. Drag
  /// updates rebuild only the seek indicator, not the controls.
  final _seekDelta = ValueNotifier<double?>(null);
  double _seekStartSeconds = 0;
  double _dragStartX = 0;

  // Full player-width drag = 120 s of seek (VLC-like fixed physical feel).
  static const double _seekWidthRatio = 120.0;

  /// Cached: the controls update themselves from the controller, so
  /// rebuilding this layer never needs to rebuild them.
  Widget? _cachedControls;
  Widget get _controls => _cachedControls ??= ValueListenableBuilder<bool>(
    valueListenable: widget.overlayController.isVisible,
    builder: (context, visible, child) => AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: visible ? 1.0 : 0.0,
      child: IgnorePointer(ignoring: !visible, child: child),
    ),
    child: ControlsOverlay(controller: widget.controller),
  );

  double get _durationSeconds =>
      widget.controller.metadata.duration.inMilliseconds / 1000;

  double _targetSeconds(double delta) =>
      (_seekStartSeconds + delta).clamp(0.0, _durationSeconds);

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_durationSeconds == 0) return;
    _dragStartX = details.localPosition.dx;
    _seekStartSeconds = widget.controller.currentTime;
    widget.overlayController.cancelTimer();
    _seekDelta.value = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_seekDelta.value == null) return;
    final playerWidth = context.size?.width ?? 1;
    final dx = details.localPosition.dx - _dragStartX;
    _seekDelta.value = (dx / playerWidth) * _seekWidthRatio;
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    final delta = _seekDelta.value;
    if (delta == null) return;
    widget.controller.seekTo(
      seconds: _targetSeconds(delta),
      allowSeekAhead: true,
    );
    _endSeek();
  }

  void _endSeek() {
    if (_seekDelta.value == null) return;
    widget.overlayController.resetTimer();
    _seekDelta.value = null;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final fullScreen = YoutubeFullScreen.of(context, listen: false);
    if (velocity < 0) {
      fullScreen.enter();
    } else if (velocity > 0) {
      fullScreen.exit();
    }
  }

  @override
  void didUpdateWidget(_ControlsLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.overlayController != widget.overlayController) {
      _cachedControls = null;
    }
  }

  @override
  void dispose() {
    _seekDelta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFullScreen = YoutubeFullScreen.of(context).isFullScreen;
    // Inline inside a scroll view, vertical drags belong to the scroll view.
    final verticalDrag =
        widget.enableVerticalDrag &&
        (isFullScreen || Scrollable.maybeOf(context) == null);
    final seekable = widget.showDefaultControls;

    return GestureDetector(
      behavior: .translucent,
      onTap: widget.overlayController.toggle,
      onHorizontalDragStart: seekable ? _onHorizontalDragStart : null,
      onHorizontalDragUpdate: seekable ? _onHorizontalDragUpdate : null,
      onHorizontalDragEnd: seekable ? _onHorizontalDragEnd : null,
      onHorizontalDragCancel: seekable ? _endSeek : null,
      onVerticalDragEnd: verticalDrag ? _onVerticalDragEnd : null,
      child: !widget.showDefaultControls
          ? const SizedBox.expand()
          : Stack(
              fit: .expand,
              children: [
                _controls,
                ValueListenableBuilder<double?>(
                  valueListenable: _seekDelta,
                  builder: (context, delta, _) => delta == null
                      ? const SizedBox.shrink()
                      : Center(
                          child: _SeekIndicator(
                            deltaSeconds: delta,
                            targetSeconds: _targetSeconds(delta),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class const _SeekIndicator({
  required final double deltaSeconds,
  required final double targetSeconds,
}) extends StatelessWidget {
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
        mainAxisSize: .min,
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
