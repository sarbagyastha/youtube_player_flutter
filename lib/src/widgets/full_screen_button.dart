import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/src/player/youtube_player.dart';

class FullScreenButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    YoutubePlayerController controller = YoutubePlayerController.of(context);
    return IconButton(
      icon: Icon(
        controller.value.isFullScreen
            ? Icons.fullscreen_exit
            : Icons.fullscreen,
        color: Colors.white,
      ),
      onPressed: () {
        if (controller.value.isFullScreen) {
          controller.exitFullScreen();
        } else {
          controller.enterFullScreen();
        }
      },
    );
  }
}
