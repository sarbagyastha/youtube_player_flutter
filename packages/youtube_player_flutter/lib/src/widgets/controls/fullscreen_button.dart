import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';
import '../../theme/youtube_player_theme.dart';

/// Toggles fullscreen mode.
class FullscreenButton extends StatelessWidget {
  const FullscreenButton({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        final isFullscreen = value.fullScreenOption.enabled;
        return IconButton(
          icon: Icon(
            isFullscreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            color: theme.controlsColor,
          ),
          onPressed: () {
            controller.toggleFullScreen();
            OverlayControllerScope.of(context).resetTimer();
          },
        );
      },
    );
  }
}
