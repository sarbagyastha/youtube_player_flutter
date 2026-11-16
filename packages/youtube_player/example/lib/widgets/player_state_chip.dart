import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import 'pill.dart';

/// Shows a [PlayerState] as a colored pill.
class const PlayerStateChip(final PlayerState state, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (state) {
      .playing => ('Playing', Icons.graphic_eq, Colors.green),
      .paused => ('Paused', Icons.pause_circle_outline, Colors.orange),
      .buffering => ('Buffering', Icons.hourglass_top, Colors.blue),
      .ended => ('Ended', Icons.stop_circle_outlined, Colors.blueGrey),
      .cued => ('Cued', Icons.queue_play_next, Colors.purple),
      .unStarted => ('Not started', Icons.radio_button_unchecked, Colors.grey),
      .unknown => ('Loading', Icons.more_horiz, Colors.grey),
    };
    return Pill(label: label, icon: icon, color: color);
  }
}
