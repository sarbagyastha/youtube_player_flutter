import 'package:youtube_player_iframe/src/enums/player_state.dart';

abstract class PlaybackStatus {
  Future<double> get videoLoadedFraction;

  Future<PlayerState> get playerState;

  Future<double> get currentTime;
}
