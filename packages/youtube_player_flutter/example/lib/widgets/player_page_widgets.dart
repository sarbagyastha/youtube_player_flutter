import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key, required this.controller});

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
              PlayerStateChip(playerState: value.playerState),
            ],
          ),
        );
      },
    );
  }
}

class PlayerStateChip extends StatelessWidget {
  const PlayerStateChip({super.key, required this.playerState});

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

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.icon, required this.title, this.trailing});

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
