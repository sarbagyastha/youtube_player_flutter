import 'package:youtube_player_iframe/src/enums/player_state.dart';

/// The skeleton for playback status methods.
abstract class PlaybackStatus {
  /// Returns a number between 0 and 1 that specifies the percentage of the video that the player shows as buffered.
  Future<double> get videoLoadedFraction;

  /// Returns the state of the player.
  Future<PlayerState> get playerState;

  /// Returns the elapsed time in seconds since the video started playing.
  Future<double> get currentTime;
}
