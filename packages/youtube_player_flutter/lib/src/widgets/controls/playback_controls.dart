import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';

/// Three centered circular buttons: previous | play-pause | next.
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleButton(
          icon: Icons.skip_previous_rounded,
          onTap: () {
            controller.previousVideo();
            OverlayControllerScope.of(context).resetTimer();
          },
        ),
        const SizedBox(width: 16),
        YoutubeValueBuilder(
          controller: controller,
          buildWhen: (o, n) => o.playerState != n.playerState,
          builder: (context, value) {
            final isPlaying = value.playerState == PlayerState.playing;
            return _CircleButton(
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              diameter: 72,
              iconSize: 36,
              onTap: () {
                isPlaying
                    ? controller.pauseVideo()
                    : controller.playVideo();
                OverlayControllerScope.of(context).resetTimer();
              },
            );
          },
        ),
        const SizedBox(width: 16),
        _CircleButton(
          icon: Icons.skip_next_rounded,
          onTap: () {
            controller.nextVideo();
            OverlayControllerScope.of(context).resetTimer();
          },
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.diameter = 56,
    this.iconSize = 28,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double diameter;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}
