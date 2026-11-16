import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../utils/format.dart';
import 'pill.dart';
import 'player_state_chip.dart';

/// Title, channel and status of the current video, plus error banners.
class const VideoHeader({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return YoutubeValueBuilder(
      builder: (context, value) {
        final meta = value.metaData;
        return Padding(
          padding: const .symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                meta.title.isEmpty ? 'Loading…' : meta.title,
                maxLines: 2,
                overflow: .ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: .w700),
              ),
              if (meta.author.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        meta.author.characters.first.toUpperCase(),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meta.author,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PlayerStateChip(value.playerState),
                  Pill(
                    label: formatRate(value.playbackRate),
                    icon: Icons.slow_motion_video,
                  ),
                  if (meta.duration > .zero)
                    Pill(
                      label: formatDuration(meta.duration),
                      icon: Icons.schedule,
                      color: theme.colorScheme.secondary,
                    ),
                  if (value.playbackQuality case final quality?
                      when quality.isNotEmpty)
                    Pill(
                      label: quality,
                      icon: Icons.high_quality_outlined,
                      color: theme.colorScheme.tertiary,
                    ),
                  if (value.isFullScreen)
                    const Pill(label: 'Fullscreen', icon: Icons.fit_screen),
                ],
              ),
              if (value.isAutoplayBlocked)
                const _Banner(
                  icon: Icons.block,
                  message: 'Autoplay was blocked. Press play to start.',
                ),
              if (value.hasError)
                _Banner(
                  icon: Icons.error_outline,
                  message:
                      'Player error: ${value.error.name} '
                      '(code ${value.error.code})',
                  error: true,
                ),
              if (value.loadError case final error?)
                _Banner(
                  icon: Icons.cloud_off,
                  message: 'Load error: ${error.description}',
                  error: true,
                ),
            ],
          ),
        );
      },
    );
  }
}

class const _Banner({
  required final IconData icon,
  required final String message,
  final bool error = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = error
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final foreground = error
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Padding(
      padding: const .only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: .circular(14),
        ),
        child: Padding(
          padding: const .all(12),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
