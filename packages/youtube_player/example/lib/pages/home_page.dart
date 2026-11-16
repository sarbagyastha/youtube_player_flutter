import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/demos.dart';
import '../widgets/demo_card.dart';

/// The gallery of demos.
class const HomePage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Row(
              mainAxisSize: .min,
              children: [
                Icon(
                  Icons.smart_display_rounded,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 10),
                const Text('youtube_player'),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const .fromLTRB(16, 0, 16, 16),
              child: Text(
                'The YouTube IFrame player in native WebViews on Android, '
                'iOS, macOS and the web. Pick a demo to explore a feature.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const .fromLTRB(16, 0, 16, 32),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                const gap = 16.0;
                final width = constraints.crossAxisExtent;
                final columns = math.max(1, math.min(4, width ~/ 340));
                final tile = (width - gap * (columns - 1)) / columns;
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                    mainAxisExtent: tile * 9 / 16 + 96,
                  ),
                  itemCount: demos.length,
                  itemBuilder: (_, i) => DemoCard(demos[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
