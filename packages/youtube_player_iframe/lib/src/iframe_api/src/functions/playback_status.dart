import 'package:youtube_player_iframe/src/enums/player_state.dart';

abstract class PlaybackStatus {
  double get videoLoadedFraction;

  PlayerState get playerState;

  double get currentTime;
}
