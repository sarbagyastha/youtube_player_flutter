import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../theme/youtube_player_theme.dart';
import 'speed_control.dart';

/// Top gradient bar showing the video title and speed control.
class TitleBar extends StatelessWidget {
  const TitleBar({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    return Container(
      decoration: BoxDecoration(gradient: theme.topGradient),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: YoutubeValueBuilder(
        controller: controller,
        buildWhen: (o, n) => o.metaData != n.metaData,
        builder: (context, value) {
          return Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    value.metaData.title,
                    style: theme.titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SpeedControl(controller: controller),
            ],
          );
        },
      ),
    );
  }
}
