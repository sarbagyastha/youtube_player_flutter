import 'package:material_ui/material_ui.dart';

/// A titled card that groups the controls of one feature.
class const SectionCard({
  super.key,
  required final String title,
  required final Widget child,
  final IconData? icon,

  /// A short caveat, e.g. which platforms support the feature.
  final String? note,
  final Widget? trailing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          mainAxisSize: .min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: .w600,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            if (note != null)
              Padding(
                padding: const .only(top: 6),
                child: Row(
                  crossAxisAlignment: .start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
