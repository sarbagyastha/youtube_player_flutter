abstract class PlayerSettings {
  void setSize(double width, double height);

  void setPlaybackRate(double suggestedRate);

  void setLoop({required bool loopPlaylists});

  void setShuffle({required bool shufflePlaylists});

  Future<double> get playbackRate;

  Future<List<double>> get availablePlaybackRates;
}
