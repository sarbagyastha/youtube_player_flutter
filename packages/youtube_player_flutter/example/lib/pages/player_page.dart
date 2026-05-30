import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../data.dart';
import '../widgets/custom_builder_demo.dart';
import '../widgets/thumbnail_card.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late YoutubePlayerController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoIds[_currentIndex],
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: false,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _loadVideo(int index) {
    setState(() => _currentIndex = index);
    _controller.loadVideoById(videoId: videoIds[index]);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Player Flutter'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          YoutubePlayer(controller: _controller),
          _NowPlaying(controller: _controller),
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.queue_music_rounded,
            title: 'Playlist',
            trailing: Text(
              '${videoIds.length} videos',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: CarouselView(
              itemExtent: 190,
              shrinkExtent: 110,
              itemSnapping: false,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onTap: _loadVideo,
              children: [
                for (var i = 0; i < videoIds.length; i++)
                  ThumbnailCard(videoId: videoIds[i], selected: i == _currentIndex),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Divider(height: 0, indent: 16, endIndent: 16),
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.tune_rounded,
            title: 'Custom Controls',
          ),
          const SizedBox(height: 10),
          const CustomBuilderDemo(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.metaData != n.metaData || o.playerState != n.playerState,
      builder: (context, value) {
        final title = value.metaData.title;
        final author = value.metaData.author;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Loading…' : title,
                      style: tt.titleSmall?.copyWith(
                        color: title.isEmpty ? cs.onSurfaceVariant : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (author.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        author,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StateChip(playerState: value.playerState),
            ],
          ),
        );
      },
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.playerState});

  final PlayerState playerState;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (label, color) = switch (playerState) {
      PlayerState.playing => ('Playing', cs.primary),
      PlayerState.paused => ('Paused', cs.onSurfaceVariant),
      PlayerState.buffering => ('Buffering', cs.tertiary),
      PlayerState.ended => ('Ended', cs.error),
      _ => ('', cs.onSurfaceVariant),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(title, style: tt.titleSmall?.copyWith(color: cs.onSurface)),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}
