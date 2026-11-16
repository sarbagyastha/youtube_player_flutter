import 'package:material_ui/material_ui.dart';

/// A labelled value, laid out in a responsive grid by [StatGrid].
class const StatTile({
  super.key,
  required final String label,
  required final String value,
  final IconData? icon,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: .circular(14),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    label,
                    overflow: .ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: .ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: .w600,
                fontFeatures: const [.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays out [StatTile]s two or three per row.
class const StatGrid({super.key, required final List<Widget> children})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth > 480 ? 3 : 2;
      const gap = 8.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
