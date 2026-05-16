import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_player_iframe_example/widgets/shared/player_state_badge.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: YoutubeValueBuilder(
        buildWhen: (o, n) =>
            o.metaData != n.metaData ||
            o.playbackQuality != n.playbackQuality ||
            o.playerState != n.playerState ||
            o.error != n.error,
        builder: (context, value) {
          final meta = value.metaData;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                meta.title.isEmpty ? 'No video loaded' : meta.title,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Channel row
              if (meta.author.isNotEmpty) ...[
                _ChannelRow(author: meta.author),
                const SizedBox(height: 6),
              ],

              // Info chips + state badge
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PlayerStateBadge(state: value.playerState),
                  if (meta.duration > Duration.zero)
                    _InfoChip(
                      icon: Icons.schedule_rounded,
                      label: _formatDuration(meta.duration),
                    ),
                  if (value.playbackQuality != null)
                    _InfoChip(
                      icon: Icons.hd_rounded,
                      label: value.playbackQuality!,
                    ),
                  if (meta.videoId.isNotEmpty)
                    _InfoChip(
                      icon: Icons.tag_rounded,
                      label: meta.videoId,
                    ),
                  if (value.hasError)
                    _InfoChip(
                      icon: Icons.error_outline_rounded,
                      label: value.error.name,
                      isError: true,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.author});

  final String author;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: cs.primaryContainer,
          child: Icon(
            Icons.person_rounded,
            size: 16,
            color: cs.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            author,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.isError = false,
  });

  final IconData icon;
  final String label;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isError ? cs.errorContainer : cs.surfaceContainerHighest;
    final fg = isError ? cs.onErrorContainer : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall!
                .copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
