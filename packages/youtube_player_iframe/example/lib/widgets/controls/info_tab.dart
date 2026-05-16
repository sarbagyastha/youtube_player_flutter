import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_player_iframe_example/widgets/shared/labeled_value.dart';
import 'package:youtube_player_iframe_example/widgets/shared/player_state_badge.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoutubeValueBuilder(
            buildWhen: (o, n) =>
                o.metaData != n.metaData ||
                o.playbackQuality != n.playbackQuality,
            builder: (context, value) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledValue('Title', value.metaData.title),
                  const SizedBox(height: 8),
                  LabeledValue('Channel', value.metaData.author),
                  const SizedBox(height: 8),
                  LabeledValue(
                    'Duration',
                    _formatDuration(value.metaData.duration),
                  ),
                  const SizedBox(height: 8),
                  LabeledValue('Video ID', value.metaData.videoId),
                  const SizedBox(height: 8),
                  LabeledValue('Quality', value.playbackQuality ?? '—'),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          YoutubeValueBuilder(
            buildWhen: (o, n) =>
                o.playerState != n.playerState || o.error != n.error,
            builder: (context, value) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'State: ',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(width: 8),
                      PlayerStateBadge(state: value.playerState),
                    ],
                  ),
                  if (value.hasError) ...[
                    const SizedBox(height: 12),
                    _ErrorCard(error: value.error),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final YoutubeError error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              error.name,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
