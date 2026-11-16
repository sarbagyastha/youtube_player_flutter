// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

import '../controller.dart';
import '../value.dart';
import 'value_builder.dart';

/// Displays the player of a [YoutubePlayerController].
///
/// Renders only the YouTube IFrame player, with YouTube's own controls. To
/// replace them with Flutter widgets, pass [controlsBuilder].
///
/// Fullscreen is presented by the platform itself (the player's fullscreen
/// button, or [YoutubePlayerController.enterFullScreen]).
class const YoutubePlayer({
  super.key,

  /// The controller driving this player.
  required final YoutubePlayerController controller,

  /// Width / height of the player.
  final double aspectRatio = 16 / 9,

  /// Gestures the player should win over its ancestors (e.g. in scroll views).
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers =
      const {},

  /// Shown behind the player and while it loads.
  final Color backgroundColor = const Color(0xFF000000),

  /// Keeps the player alive inside lazily built lists.
  final bool keepAlive = false,

  /// Defers `fromVideoId(autoPlay: true)` until at least half of the player
  /// is visible, and lets only one player autoplay at a time, as required by
  /// YouTube's Required Minimum Functionality.
  final bool autoPlayWhenVisible = true,

  /// Builds Flutter controls that replace YouTube's own.
  ///
  /// When set, the player is created with its native controls, keyboard
  /// shortcuts and fullscreen button turned off, and the iframe ignores
  /// pointer events, so all input reaches this overlay. The overlay is laid
  /// out over exactly the player's [aspectRatio] box and rebuilds on every
  /// player value change. `context.ytController` works inside it.
  ///
  /// Decide on this before the player is first shown: the native controls
  /// are fixed when the player is created.
  ///
  /// The overlay is not shown in native fullscreen. A custom fullscreen
  /// button can call [YoutubePlayerController.enterFullScreen] on Android,
  /// macOS and the web; iPhone only allows the player's own button.
  final Widget Function(BuildContext context, YoutubePlayerValue value)?
  controlsBuilder,
}) extends StatefulWidget {
  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer>
    with AutomaticKeepAliveClientMixin {
  YoutubePlayerHost? _host;
  final _scrollPositions = <ScrollPosition>[];
  var _visibilityCheckScheduled = false;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(YoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      (oldWidget.controlsBuilder == null) == (widget.controlsBuilder == null) ||
          _host == null ||
          oldWidget.controller != widget.controller,
      'YoutubePlayer.controlsBuilder was added or removed after the player '
      'was created. Native controls are fixed at creation, so decide on '
      'controlsBuilder before the player is first shown.',
    );
    if (oldWidget.controller != widget.controller) {
      _host = null;
      _attach(widget.controller);
    } else if (oldWidget.backgroundColor != widget.backgroundColor) {
      _host?.setBackgroundColor(widget.backgroundColor);
    }
    if (oldWidget.keepAlive != widget.keepAlive) updateKeepAlive();
  }

  Future<void> _attach(YoutubePlayerController controller) async {
    if (!widget.autoPlayWhenVisible) controller.startPendingAutoPlay();
    controller.customControls = widget.controlsBuilder != null;
    final host = await controller.host;
    if (!mounted || controller != widget.controller) return;
    await host.setBackgroundColor(widget.backgroundColor);
    setState(() => _host = host);
  }

  // MARK: Visibility-gated autoplay

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenToScrollables();
    _scheduleVisibilityCheck();
  }

  void _listenToScrollables() {
    for (final position in _scrollPositions) {
      position.removeListener(_scheduleVisibilityCheck);
    }
    _scrollPositions.clear();
    if (!widget.autoPlayWhenVisible) return;
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      _scrollPositions.add(
        scrollable.position..addListener(_scheduleVisibilityCheck),
      );
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
  }

  void _scheduleVisibilityCheck() {
    if (_visibilityCheckScheduled ||
        !widget.autoPlayWhenVisible ||
        !widget.controller.hasPendingAutoPlay) {
      return;
    }
    _visibilityCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;
      if (!mounted || !widget.controller.hasPendingAutoPlay) return;
      if (_visibleFraction() >= 0.5) {
        widget.controller.startPendingAutoPlay();
      } else if (_scrollPositions.isEmpty) {
        // Nothing will notify us; poll lightly until visible.
        Future<void>.delayed(
          const Duration(milliseconds: 250),
          _scheduleVisibilityCheck,
        );
      }
    });
  }

  double _visibleFraction() {
    if (!TickerMode.valuesOf(context).enabled) return 0;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return 0;
    final bounds = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    final area = bounds.width * bounds.height;
    if (area <= 0) return 0;
    final view = View.of(context);
    var visible = bounds.intersect(
      Offset.zero & (view.physicalSize / view.devicePixelRatio),
    );
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null && !visible.isEmpty) {
      if (scrollable.context.findRenderObject() case final RenderBox viewport
          when viewport.hasSize) {
        visible = visible.intersect(
          MatrixUtils.transformRect(
            viewport.getTransformTo(null),
            Offset.zero & viewport.size,
          ),
        );
      }
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    if (visible.isEmpty) return 0;
    return visible.width * visible.height / area;
  }

  @override
  void dispose() {
    for (final position in _scrollPositions) {
      position.removeListener(_scheduleVisibilityCheck);
    }
    super.dispose();
  }

  // MARK: Build

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final host = _host;
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          assert(() {
            if (constraints.maxWidth < 200 || constraints.maxHeight < 200) {
              debugPrint(
                'YoutubePlayer is ${constraints.biggest}; YouTube requires the '
                'player viewport to be at least 200x200.',
              );
            }
            return true;
          }());
          return ColoredBox(
            color: widget.backgroundColor,
            child: ClipRect(
              child: Stack(
                fit: .expand,
                children: [
                  if (host != null)
                    RepaintBoundary(
                      child: host.buildView(
                        gestureRecognizers: widget.gestureRecognizers,
                      ),
                    ),
                  if (widget.controlsBuilder case final builder?)
                    YoutubePlayerControllerProvider(
                      controller: widget.controller,
                      child: YoutubeValueBuilder(
                        controller: widget.controller,
                        builder: builder,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
