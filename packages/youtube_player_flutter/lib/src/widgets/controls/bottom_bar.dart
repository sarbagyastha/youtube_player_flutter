import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../theme/youtube_player_theme.dart';
import 'playback_controls.dart';
import 'progress_bar.dart';

/// Bottom gradient bar with the seek bar and playback controls.
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
          ProgressBar(controller: controller),
          PlaybackControls(controller: controller),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
