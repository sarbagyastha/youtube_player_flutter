// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

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
      .playing => (cs.primaryContainer, cs.onPrimaryContainer),
      .paused => (cs.tertiaryContainer, cs.onTertiaryContainer),
      .buffering => (cs.secondaryContainer, cs.onSecondaryContainer),
      .ended => (cs.errorContainer, cs.onErrorContainer),
      .cued => (cs.secondaryContainer, cs.onSecondaryContainer),
      _ => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };
  }
}
