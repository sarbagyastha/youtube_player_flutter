import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';
import '../../theme/youtube_player_theme.dart';

/// Seek bar with elapsed/remaining time labels, driven by [YoutubeVideoState].
class ProgressBar extends StatefulWidget {
  const ProgressBar({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  bool _isSeeking = false;
  double _seekValue = 0;

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    return StreamBuilder<YoutubeVideoState>(
      stream: widget.controller.videoStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const YoutubeVideoState();
        final duration = widget.controller.metadata.duration;
        final totalSeconds = duration.inSeconds.toDouble();

        final position = _isSeeking
            ? Duration(seconds: _seekValue.toInt())
            : state.position;
        final sliderValue = totalSeconds > 0
            ? position.inSeconds.toDouble().clamp(0.0, totalSeconds)
            : 0.0;
        final buffered = (state.loadedFraction * totalSeconds).clamp(
          0.0,
          totalSeconds,
        );

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
            padding: EdgeInsets.symmetric(horizontal: 16),
            secondaryTrackValue: totalSeconds > 0 ? buffered : 0,
            max: totalSeconds > 0 ? totalSeconds : 1,
            onChangeStart: (value) {
              setState(() {
                _isSeeking = true;
                _seekValue = value;
              });
              OverlayControllerScope.of(context).cancelTimer();
            },
            onChanged: (value) {
              setState(() => _seekValue = value);
              widget.controller.seekTo(seconds: value, allowSeekAhead: false);
            },
            onChangeEnd: (value) {
              widget.controller.seekTo(seconds: value, allowSeekAhead: true);
              setState(() => _isSeeking = false);
              OverlayControllerScope.of(context).resetTimer();
            },
          ),
        );
      },
    );
  }
}
