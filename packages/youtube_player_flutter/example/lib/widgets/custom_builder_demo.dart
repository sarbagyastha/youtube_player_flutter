import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Demonstrates the [YoutubePlayerBuilder] callback for fully custom controls.
class CustomBuilderDemo extends StatefulWidget {
  const CustomBuilderDemo({super.key});

  @override
  State<CustomBuilderDemo> createState() => _CustomBuilderDemoState();
}

class _CustomBuilderDemoState extends State<CustomBuilderDemo> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: 'j4lDDQTKN8s',
      autoPlay: false,
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      // Custom builder replaces the entire default controls overlay.
      // Use Stack to overlay controls on top of the player surface.
      builder: (context, player, ctrl) => Stack(
        children: [
          AbsorbPointer(child: player),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _MinimalControls(controller: ctrl),
          ),
        ],
      ),
    );
  }
}

/// A minimal custom controls bar — the simplest possible builder output.
class _MinimalControls extends StatelessWidget {
  const _MinimalControls({required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            'Custom controls',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const Spacer(),
          YoutubeValueBuilder(
            controller: controller,
            buildWhen: (o, n) => o.playerState != n.playerState,
            builder: (context, value) {
              final isPlaying = value.playerState == PlayerState.playing;
              return IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: cs.primary,
                ),
                onPressed: isPlaying ? controller.pauseVideo : controller.playVideo,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.stop_rounded, color: cs.onSurfaceVariant),
            onPressed: controller.stopVideo,
          ),
          FullscreenButton(controller: controller),
        ],
      ),
    );
  }
}
