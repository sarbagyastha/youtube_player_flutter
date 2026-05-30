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
        // Keep blocking until the stream position catches up to where we seeked.
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

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);
    final duration = widget.controller.metadata.duration;
    final totalSeconds = duration.inSeconds.toDouble();

    final sliderValue = totalSeconds > 0
        ? (_isSeeking ? _seekValue : _videoState.position.inSeconds.toDouble())
            .clamp(0.0, totalSeconds)
        : 0.0;
    final buffered =
        (_videoState.loadedFraction * totalSeconds).clamp(0.0, totalSeconds);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: theme.progressBarActiveColor,
        thumbColor: theme.progressBarActiveColor,
        inactiveTrackColor: theme.progressBarBackgroundColor,
        secondaryActiveTrackColor: theme.progressBarBufferedColor,
        overlayColor: theme.progressBarActiveColor.withValues(alpha: 0.2),
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      ),
      child: Slider(
        value: sliderValue,
        padding: EdgeInsets.fromLTRB(
          widget.leftPadding > 0 ? widget.leftPadding : 16,
          0,
          widget.rightPadding > 0 ? widget.rightPadding : 16,
          0,
        ),
        secondaryTrackValue: totalSeconds > 0 ? buffered : 0,
        max: totalSeconds > 0 ? totalSeconds : 1,
        onChangeStart: (value) {
          _seekClearTimer?.cancel();
          setState(() {
            _isSeeking = true;
            _seekValue = value;
          });
          OverlayControllerScope.of(context).cancelTimer();
        },
        onChanged: (value) {
          setState(() => _seekValue = value);
        },
        onChangeEnd: (value) {
          widget.controller.seekTo(seconds: value, allowSeekAhead: true);
          // Safety fallback: clear seeking state after 1.5 s if the stream
          // never reports a position close enough (e.g. seeking to end of video).
          _seekClearTimer?.cancel();
          _seekClearTimer = Timer(const Duration(milliseconds: 1500), () {
            if (mounted) setState(() => _isSeeking = false);
          });
          OverlayControllerScope.of(context).resetTimer();
        },
      ),
    );
  }
}
