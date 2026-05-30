import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';
import '../../theme/youtube_player_theme.dart';

/// Seek bar with elapsed/remaining time labels, driven by [YoutubeVideoState].
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
  late StreamSubscription<YoutubeVideoState> _subscription;
  Timer? _seekClearTimer;
  YoutubeVideoState _videoState = const YoutubeVideoState();
  bool _isSeeking = false;
  double _seekValue = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.videoStateStream.listen((state) {
      if (!mounted) return;
      if (_isSeeking) {
        final diff = state.position.inSeconds.toDouble() - _seekValue;
        if (diff.abs() < 1.0) {
          _seekClearTimer?.cancel();
          setState(() {
            _videoState = state;
            _isSeeking = false;
          });
        }
      } else {
        setState(() => _videoState = state);
      }
    });
  }

  @override
  void dispose() {
    _seekClearTimer?.cancel();
    _subscription.cancel();
    super.dispose();
  }

  void _seekTo(double seconds) {
    widget.controller.seekTo(seconds: seconds, allowSeekAhead: true);
    _seekClearTimer?.cancel();
    _seekClearTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isSeeking = false);
    });
  }

  void _onDragStart(double localX, double trackWidth) {
    if (trackWidth <= 0) return;
    final totalSeconds =
        widget.controller.metadata.duration.inSeconds.toDouble();
    if (totalSeconds <= 0) return;
    final seconds =
        ((localX / trackWidth) * totalSeconds).clamp(0.0, totalSeconds);
    _seekClearTimer?.cancel();
    setState(() {
      _isSeeking = true;
      _seekValue = seconds;
    });
    OverlayControllerScope.of(context).cancelTimer();
  }

  void _onDragUpdate(double localX, double trackWidth) {
    if (trackWidth <= 0) return;
    final totalSeconds =
        widget.controller.metadata.duration.inSeconds.toDouble();
    if (totalSeconds <= 0) return;
    final seconds =
        ((localX / trackWidth) * totalSeconds).clamp(0.0, totalSeconds);
    setState(() => _seekValue = seconds);
  }

  void _onDragEnd() {
    _seekTo(_seekValue);
    OverlayControllerScope.of(context).resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);
    final duration = widget.controller.metadata.duration;
    final totalSeconds = duration.inSeconds.toDouble();

    final playedFraction = totalSeconds > 0
        ? (_isSeeking
                ? _seekValue
                : _videoState.position.inSeconds.toDouble())
            .clamp(0.0, totalSeconds) /
            totalSeconds
        : 0.0;
    final bufferedFraction = totalSeconds > 0
        ? _videoState.loadedFraction.clamp(0.0, 1.0)
        : 0.0;

    final hPad = EdgeInsets.fromLTRB(
      widget.leftPadding > 0 ? widget.leftPadding : 16,
      0,
      widget.rightPadding > 0 ? widget.rightPadding : 16,
      0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth =
            constraints.maxWidth - hPad.left - hPad.right;

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
                child: _SeekTrack(
                  playedFraction: playedFraction,
                  bufferedFraction: bufferedFraction,
                  activeColor: theme.progressBarActiveColor,
                  bufferedColor: theme.progressBarBufferedColor,
                  backgroundColor: theme.progressBarBackgroundColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeekTrack extends StatelessWidget {
  const _SeekTrack({
    required this.playedFraction,
    required this.bufferedFraction,
    required this.activeColor,
    required this.bufferedColor,
    required this.backgroundColor,
  });

  final double playedFraction;
  final double bufferedFraction;
  final Color activeColor;
  final Color bufferedColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 3),
      painter: _TrackPainter(
        played: playedFraction,
        buffered: bufferedFraction,
        activeColor: activeColor,
        bufferedColor: bufferedColor,
        backgroundColor: backgroundColor,
        thumbRadius: 6,
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.played,
    required this.buffered,
    required this.activeColor,
    required this.bufferedColor,
    required this.backgroundColor,
    required this.thumbRadius,
  });

  final double played;
  final double buffered;
  final Color activeColor;
  final Color bufferedColor;
  final Color backgroundColor;
  final double thumbRadius;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(1.5);
    final cy = size.height / 2;
    final trackRect = Rect.fromLTWH(0, cy - size.height / 2, size.width, size.height);

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, radius),
      Paint()..color = backgroundColor,
    );

    // Buffered
    if (buffered > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, cy - size.height / 2, size.width * buffered, size.height),
          radius,
        ),
        Paint()..color = bufferedColor,
      );
    }

    // Played
    if (played > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, cy - size.height / 2, size.width * played, size.height),
          radius,
        ),
        Paint()..color = activeColor,
      );
    }

    // Thumb
    canvas.drawCircle(
      Offset(size.width * played, cy),
      thumbRadius,
      Paint()..color = activeColor,
    );
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.played != played ||
      old.buffered != buffered ||
      old.activeColor != activeColor ||
      old.bufferedColor != bufferedColor ||
      old.backgroundColor != backgroundColor;
}
