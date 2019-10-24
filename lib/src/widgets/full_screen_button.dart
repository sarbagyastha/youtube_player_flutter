import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';

/// A widget to display the full screen toggle button.
class FullScreenButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    YoutubePlayerController controller = YoutubePlayerController.of(context);
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        return IconButton(
          icon: Icon(
            value.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: Colors.white,
          ),
          onPressed: () {
            if (value.isFullScreen) {
              controller.exitFullScreenMode();
            } else {
              controller.enterFullScreenMode();
            }
          },
        );
      },
    );
  }
}
