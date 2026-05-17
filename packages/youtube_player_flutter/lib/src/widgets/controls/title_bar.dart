import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../theme/youtube_player_theme.dart';
import 'speed_control.dart';

/// Top action bar with speed control aligned to the right.
class TitleBar extends StatelessWidget {
  const TitleBar({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    return Container(
      decoration: BoxDecoration(gradient: theme.topGradient),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          const Spacer(),
          SpeedControl(controller: controller, useIcon: true),
        ],
      ),
    );
  }
}
