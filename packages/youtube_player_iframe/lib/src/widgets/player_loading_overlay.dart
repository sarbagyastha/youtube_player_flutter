import '../enums/player_state.dart';
import '../player_value.dart';

/// Whether the loading thumbnail should cover the player surface.
bool shouldShowPlayerLoadingOverlay(YoutubePlayerValue value) {
  return !value.hasError &&
      (value.playerState == PlayerState.unknown ||
          value.playerState == PlayerState.unStarted);
}
