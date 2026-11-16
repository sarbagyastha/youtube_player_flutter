import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

/// Previous, −10 s, play / pause, +10 s and next.
class const TransportControls({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    void skip(double by) => controller.seekTo(
      seconds: math.max(0, controller.currentTime + by),
      allowSeekAhead: true,
    );
    return YoutubeValueBuilder(
      buildWhen: (a, b) => a.playerState != b.playerState,
      builder: (context, value) {
        // Buffering counts as playing, so the button doesn't flicker.
        final playing = value.playerState.isActive;
        return Row(
          mainAxisAlignment: .spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Previous',
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: controller.previousVideo,
            ),
            IconButton(
              tooltip: 'Back 10 seconds',
              icon: const Icon(Icons.replay_10_rounded),
              onPressed: () => skip(-10),
            ),
            IconButton.filled(
              tooltip: playing ? 'Pause' : 'Play',
              iconSize: 36,
              style: IconButton.styleFrom(padding: const .all(14)),
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: playing ? controller.pauseVideo : controller.playVideo,
            ),
            IconButton(
              tooltip: 'Forward 10 seconds',
              icon: const Icon(Icons.forward_10_rounded),
              onPressed: () => skip(10),
            ),
            IconButton(
              tooltip: 'Next',
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: controller.nextVideo,
            ),
          ],
        );
      },
    );
  }
}
