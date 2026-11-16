import 'package:material_ui/material_ui.dart';

/// A small rounded label, tinted with [color].
class const Pill({
  super.key,
  required final String label,
  final IconData? icon,
  final Color? color,
  final bool filled = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    final foreground = filled ? Colors.white : tint;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? tint : tint.withValues(alpha: .14),
        borderRadius: .circular(999),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: .min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: foreground, fontWeight: .w600),
            ),
          ],
        ),
      ),
    );
  }
}
