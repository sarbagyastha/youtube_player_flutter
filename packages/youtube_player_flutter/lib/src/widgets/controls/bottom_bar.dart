import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../theme/youtube_player_theme.dart';
import '../../utils/duration_formatter.dart';
import 'fullscreen_button.dart';
import 'progress_bar.dart';

/// Bottom gradient bar: time pill + fullscreen button, then a thin seek slider.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    return Container(
      decoration: BoxDecoration(gradient: theme.bottomGradient),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                _TimePill(controller: controller, theme: theme),
                const Spacer(),
                FullscreenButton(controller: controller),
              ],
            ),
          ),
          ProgressBar(controller: controller),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.controller, required this.theme});

  final YoutubePlayerController controller;
  final YoutubePlayerThemeResolver theme;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<YoutubeVideoState>(
      stream: controller.videoStateStream,
      builder: (context, snapshot) {
        final position = snapshot.data?.position ?? Duration.zero;
        final duration = controller.metadata.duration;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${position.toHhMmSs()} / ${duration.toHhMmSs()}',
            style: theme.timerStyle,
          ),
        );
      },
    );
  }
}
