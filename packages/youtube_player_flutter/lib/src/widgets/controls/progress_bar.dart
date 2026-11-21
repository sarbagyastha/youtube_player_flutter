// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../../controller/overlay_controller.dart';
import '../../controller/overlay_controller_scope.dart';
import '../../theme/youtube_player_theme.dart';

/// Seek bar driven by [YoutubeVideoState].
///
/// Position ticks only repaint the track; nothing is rebuilt. Ticks are
/// ignored while the controls overlay is hidden.
class ProgressBar extends StatefulWidget {
  const ProgressBar({
    super.key,
    required this.controller,
    this.leftPadding = 0,
    this.rightPadding = 0,
  });

  final YoutubePlayerController controller;
  final double leftPadding;
  final double rightPadding;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  late final StreamSubscription<YoutubeVideoState> _subscription;
  final _track = _TrackProgress();
  OverlayController? _overlay;
  Timer? _seekClearTimer;
  bool _isSeeking = false;
  double _seekSeconds = 0;

  double get _totalSeconds =>
      widget.controller.metadata.duration.inMicroseconds /
      Duration.microsecondsPerSecond;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.videoStateStream.listen(_onVideoState);
    // Ticks only arrive while playing; start from the last known position.
    _syncFromController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final overlay = OverlayControllerScope.maybeOf(context);
    if (overlay == _overlay) return;
    _overlay?.isVisible.removeListener(_onOverlayVisibility);
    _overlay = overlay?..isVisible.addListener(_onOverlayVisibility);
  }

  @override
  void dispose() {
    _overlay?.isVisible.removeListener(_onOverlayVisibility);
    _seekClearTimer?.cancel();
    _subscription.cancel();
    _track.dispose();
    super.dispose();
  }

  bool get _overlayVisible => _overlay?.isVisible.value ?? true;

  void _onOverlayVisibility() {
    if (_overlayVisible && !_isSeeking) _syncFromController();
  }

  void _syncFromController() => _setPosition(
    widget.controller.currentTime,
    widget.controller.videoLoadedFraction,
  );

  void _setPosition(double seconds, double loadedFraction) {
    final total = _totalSeconds;
    _track.update(
      played: total > 0 ? (seconds / total).clamp(0.0, 1.0) : 0,
      buffered: total > 0 ? loadedFraction.clamp(0.0, 1.0) : 0,
    );
  }

  void _onVideoState(YoutubeVideoState state) {
    if (!mounted) return;
    final seconds =
        state.position.inMicroseconds / Duration.microsecondsPerSecond;
    if (_isSeeking) {
      // Hold the seek target until the player catches up with it.
      if ((seconds - _seekSeconds).abs() >= 1.0) return;
      _seekClearTimer?.cancel();
      _isSeeking = false;
    } else if (!_overlayVisible) {
      return;
    }
    _setPosition(seconds, state.loadedFraction);
  }

  double _secondsAt(double localX, double trackWidth) =>
      ((localX / trackWidth) * _totalSeconds).clamp(0.0, _totalSeconds);

  void _onDragStart(double localX, double trackWidth) {
    if (trackWidth <= 0 || _totalSeconds <= 0) return;
    _seekClearTimer?.cancel();
    _isSeeking = true;
    _seekSeconds = _secondsAt(localX, trackWidth);
    _setPosition(_seekSeconds, _track.buffered);
    _overlay?.cancelTimer();
  }

  void _onDragUpdate(double localX, double trackWidth) {
    if (!_isSeeking || trackWidth <= 0) return;
    _seekSeconds = _secondsAt(localX, trackWidth);
    _setPosition(_seekSeconds, _track.buffered);
  }

  void _onDragEnd() {
    if (!_isSeeking) return;
    widget.controller.seekTo(seconds: _seekSeconds, allowSeekAhead: true);
    _seekClearTimer?.cancel();
    _seekClearTimer = Timer(const Duration(milliseconds: 1500), () {
      _isSeeking = false;
      if (mounted) _syncFromController();
    });
    _overlay?.resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);
    final hPad = EdgeInsets.fromLTRB(
      widget.leftPadding > 0 ? widget.leftPadding : 16,
      0,
      widget.rightPadding > 0 ? widget.rightPadding : 16,
      0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth - hPad.left - hPad.right;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) =>
              _onDragStart(d.localPosition.dx - hPad.left, trackWidth),
          onHorizontalDragUpdate: (d) =>
              _onDragUpdate(d.localPosition.dx - hPad.left, trackWidth),
          onHorizontalDragEnd: (_) => _onDragEnd(),
          onTapDown: (d) {
            _onDragStart(d.localPosition.dx - hPad.left, trackWidth);
            _onDragEnd();
          },
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: hPad.copyWith(top: 8),
              child: Align(
                alignment: Alignment.topCenter,
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(double.infinity, 3),
                    painter: _TrackPainter(
                      progress: _track,
                      activeColor: theme.progressBarActiveColor,
                      bufferedColor: theme.progressBarBufferedColor,
                      backgroundColor: theme.progressBarBackgroundColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Played and buffered fractions; notifies only when either changes.
class _TrackProgress extends ChangeNotifier {
  double played = 0;
  double buffered = 0;

  void update({required double played, required double buffered}) {
    if (played == this.played && buffered == this.buffered) return;
    this.played = played;
    this.buffered = buffered;
    notifyListeners();
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.progress,
    required Color activeColor,
    required Color bufferedColor,
    required Color backgroundColor,
  }) : _active = Paint()..color = activeColor,
       _buffered = Paint()..color = bufferedColor,
       _background = Paint()..color = backgroundColor,
       super(repaint: progress);

  static const _radius = Radius.circular(1.5);
  static const _thumbRadius = 6.0;

  final _TrackProgress progress;
  final Paint _active;
  final Paint _buffered;
  final Paint _background;

  @override
  void paint(Canvas canvas, Size size) {
    final played = progress.played;
    final buffered = progress.buffered;
    RRect bar(double fraction) => RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * fraction, size.height),
      _radius,
    );

    canvas.drawRRect(bar(1), _background);
    if (buffered > 0) canvas.drawRRect(bar(buffered), _buffered);
    if (played > 0) canvas.drawRRect(bar(played), _active);
    canvas.drawCircle(
      Offset(size.width * played, size.height / 2),
      _thumbRadius,
      _active,
    );
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.progress != progress ||
      old._active.color != _active.color ||
      old._buffered.color != _buffered.color ||
      old._background.color != _background.color;
}
