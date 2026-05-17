import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';
import '../../theme/youtube_player_theme.dart';
import 'speed_control.dart';

/// Top action bar: collapse button on the left; cast, CC, and settings on the right.
class TitleBar extends StatelessWidget {
  const TitleBar({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);
    final color = theme.controlsColor;

    return Container(
      decoration: BoxDecoration(gradient: theme.topGradient),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 28),
            onPressed: OverlayControllerScope.of(context).hide,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.cast_rounded, color: color),
            onPressed: null,
          ),
          IconButton(
            icon: Icon(Icons.closed_caption_rounded, color: color),
            onPressed: null,
          ),
          SpeedControl(controller: controller, useIcon: true),
        ],
      ),
    );
  }
}
