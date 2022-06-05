abstract class PlayerSettings {
  void setSize(double width, double height);

  double getPlaybackRate();

  void setPlaybackRate(double suggestedRate);

  void setLoop({required bool loopPlaylists});

  void setShuffle({required bool shufflePlaylists});

  List<double> get availablePlaybackRates;
}
