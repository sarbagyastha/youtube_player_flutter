import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/videos.dart';
import '../widgets/player_state_chip.dart';

/// Many players in one scroll view.
///
/// Each one is set to autoplay (muted); `YoutubePlayer.autoPlayWhenVisible`
/// starts it once half of it is visible and pauses the previous one.
class const PlayerListPage({super.key}) extends StatefulWidget {
  @override
  State<PlayerListPage> createState() => _PlayerListPageState();
}

class _PlayerListPageState extends State<PlayerListPage> {
  final _controllers = [
    for (final id in videoIds)
      YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: true,
        params: const YoutubePlayerParams(mute: true),
      ),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Players in a list')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.separated(
          padding: const .all(16),
          itemCount: _controllers.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) =>
              i == 0 ? const _Intro() : _PlayerCard(_controllers[i - 1]),
        ),
      ),
    ),
  );
}

class const _Intro() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    'Scroll: each player starts once half visible, and only one autoplays '
    'at a time. keepAlive keeps players alive when scrolled away.',
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

class const _PlayerCard(final YoutubePlayerController controller)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: .antiAlias,
    child: YoutubePlayerControllerProvider(
      controller: controller,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          YoutubePlayer(controller: controller, keepAlive: true),
          YoutubeValueBuilder(
            buildWhen: (a, b) =>
                a.metaData.title != b.metaData.title ||
                a.playerState != b.playerState,
            builder: (context, value) => ListTile(
              contentPadding: const .symmetric(horizontal: 16),
              title: Text(
                value.metaData.title.isEmpty
                    ? 'Loading…'
                    : value.metaData.title,
                maxLines: 1,
                overflow: .ellipsis,
              ),
              subtitle: Text(value.metaData.author),
              trailing: PlayerStateChip(value.playerState),
            ),
          ),
        ],
      ),
    ),
  );
}
