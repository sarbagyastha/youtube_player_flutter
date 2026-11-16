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
/// Fullscreen is presented by the platform itself (the player's fullscreen
/// button, or [YoutubePlayerController.enterFullScreen]); this widget only
/// renders the inline player.
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

  /// Thumbnail shown until the player is ready.
  final ThumbnailQuality thumbnailQuality = .high,

  /// Thumbnail image format.
  final ThumbnailFormat thumbnailFormat = .webp,

  /// Builds custom controls on top of the inline player. Combine with
  /// `YoutubePlayerParams(showControls: false, pointerEvents: .none)`.
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
            child: Stack(
              fit: .expand,
              children: [
                if (host != null)
                  RepaintBoundary(
                    child: host.buildView(
                      gestureRecognizers: widget.gestureRecognizers,
                    ),
                  ),
                YoutubeValueBuilder(
                  controller: widget.controller,
                  buildWhen: (a, b) => a.isReady != b.isReady,
                  builder: (context, value) => IgnorePointer(
                    ignoring: value.isReady,
                    child: AnimatedOpacity(
                      opacity: value.isReady ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      child: _Placeholder(
                        videoId: widget.controller.initialVideoId,
                        quality: widget.thumbnailQuality,
                        format: widget.thumbnailFormat,
                        color: widget.backgroundColor,
                      ),
                    ),
                  ),
                ),
                if (widget.controlsBuilder case final builder?)
                  YoutubeValueBuilder(
                    controller: widget.controller,
                    builder: builder,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class const _Placeholder({
  required final String? videoId,
  required final ThumbnailQuality quality,
  required final ThumbnailFormat format,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final background = ColoredBox(color: color);
    final id = videoId;
    if (id == null) return background;
    return Image.network(
      format.buildUrl(id, quality),
      fit: .cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => background,
      frameBuilder: (_, child, frame, _) => frame == null ? background : child,
    );
  }
}
