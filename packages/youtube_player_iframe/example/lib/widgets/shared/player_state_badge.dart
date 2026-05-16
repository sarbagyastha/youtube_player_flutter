import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class PlayerStateBadge extends StatelessWidget {
  const PlayerStateBadge({super.key, required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _colorForState(state),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        state.name,
        style: Theme.of(context)
            .textTheme
            .labelSmall!
            .copyWith(color: Colors.white),
      ),
    );
  }

  Color _colorForState(PlayerState state) {
    switch (state) {
      case PlayerState.unknown:
        return Colors.grey[700]!;
      case PlayerState.unStarted:
        return Colors.pink;
      case PlayerState.ended:
        return Colors.red;
      case PlayerState.playing:
        return Colors.blueAccent;
      case PlayerState.paused:
        return Colors.orange;
      case PlayerState.buffering:
        return Colors.yellow[700]!;
      case PlayerState.cued:
        return Colors.blue[900]!;
    }
  }
}
