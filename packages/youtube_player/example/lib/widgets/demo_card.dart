import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/demos.dart';
import 'pill.dart';

/// A gallery tile that opens [demo].
class const DemoCard(final Demo demo, {super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: demo.builder)),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: .expand,
                children: [
                  Image.network(
                    YoutubePlayerController.getThumbnail(
                      videoId: demo.thumbnailId,
                      quality: .high,
                    ),
                    fit: .cover,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: scheme.surfaceContainerHighest),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: .topCenter,
                        end: .bottomCenter,
                        colors: [Color(0x00000000), Color(0xAA000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: .circle,
                      ),
                      child: Padding(
                        padding: const .all(10),
                        child: Icon(demo.icon, color: scheme.onPrimary),
                      ),
                    ),
                  ),
                  if (demo.badge case final badge?)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Pill(
                        label: badge,
                        color: demo.badgeColor ?? scheme.primary,
                        filled: true,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const .fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      demo.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: .w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demo.description,
                      maxLines: 2,
                      overflow: .ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
