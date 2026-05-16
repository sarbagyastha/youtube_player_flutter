import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class PlayerStateBadge extends StatelessWidget {
  const PlayerStateBadge({super.key, required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _colorsForState(state, cs);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        state.name,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _colorsForState(PlayerState state, ColorScheme cs) {
    return switch (state) {
      PlayerState.playing => (cs.primaryContainer, cs.onPrimaryContainer),
      PlayerState.paused => (cs.tertiaryContainer, cs.onTertiaryContainer),
      PlayerState.buffering => (cs.secondaryContainer, cs.onSecondaryContainer),
      PlayerState.ended => (cs.errorContainer, cs.onErrorContainer),
      PlayerState.cued => (cs.secondaryContainer, cs.onSecondaryContainer),
      _ => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };
  }
}
