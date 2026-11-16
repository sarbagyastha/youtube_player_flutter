import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/videos.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/player_overlay.dart';
import '../widgets/section_card.dart';
import '../widgets/video_header.dart';

/// Replaces YouTube's controls with [PlayerOverlay].
class const CustomControlsPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Custom controls',
    create: () => YoutubePlayerController.fromVideoId(videoId: videoIds[2]),
    // No params needed: controlsBuilder turns YouTube's controls off.
    playerBuilder: (context, controller) => YoutubePlayer(
      controller: controller,
      controlsBuilder: (context, value) => PlayerOverlay(value),
    ),
    children: const [
      VideoHeader(),
      SectionCard(title: 'How it works', icon: Icons.tune, child: _Explainer()),
    ],
  );
}

class const _Explainer() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    Widget tip(IconData icon, String text) => Padding(
      padding: const .symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
    return Column(
      children: [
        tip(
          Icons.layers_outlined,
          'controlsBuilder draws Flutter widgets over the player. YouTube\'s '
          'controls, keyboard and pointer input are turned off.',
        ),
        tip(Icons.touch_app_outlined, 'Tap to show or hide the controls.'),
        tip(
          Icons.fast_forward_outlined,
          'Double-tap the left or right half to skip 10 seconds.',
        ),
        tip(Icons.fullscreen, 'The overlay is not shown in native fullscreen.'),
      ],
    );
  }
}
