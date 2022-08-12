/// The skeleton for player settings methods.
abstract class PlayerSettings {
  /// Sets the size in pixels of the <iframe> that contains the player.
  void setSize(double width, double height);

  /// This function sets the suggested playback rate for the current video.
  /// If the playback rate changes, it will only change for the video that is already cued or being played.
  /// If you set the playback rate for a cued video, that rate will still be in effect when the playVideo function is called
  /// or the user initiates playback directly through the player controls.
  /// In addition, calling functions to cue or load videos or playlists (cueVideoById, loadVideoById, etc.) will reset the playback rate to 1.
  ///
  /// Calling this function does not guarantee that the playback rate will actually change.
  /// However, if the playback rate does change, the onPlaybackRateChange event will fire,
  /// and your code should respond to the event rather than the fact that it called the [setPlaybackRate] function.
  void setPlaybackRate(double suggestedRate);

  /// This function indicates whether the video player should continuously play a playlist
  /// or if it should stop playing after the last video in the playlist ends.
  /// The default behavior is that playlists do not loop.
  ///
  /// This setting will persist even if you load or cue a different playlist,
  /// which means that if you load a playlist, call the setLoop function with a value of true,
  /// and then load a second playlist, the second playlist will also loop.
  ///
  /// If [loopPlaylists] is true, then the video player will continuously play playlists.
  /// After playing the last video in a playlist, the video player will go back to the beginning
  /// of the playlist and play it again.
  void setLoop({required bool loopPlaylists});

  /// This function indicates whether a playlist's videos should be shuffled so that
  /// they play back in an order different from the one that the playlist creator designated.
  /// If you shuffle a playlist after it has already started playing,
  /// the list will be reordered while the video that is playing continues to play.
  /// The next video that plays will then be selected based on the reordered list.
  ///
  /// This setting will not persist if you load or cue a different playlist,
  /// which means that if you load a playlist, call the setShuffle function,
  /// and then load a second playlist, the second playlist will not be shuffled.
  ///
  /// If [shufflePlaylists] is true, then YouTube will shuffle the playlist order.
  /// If you instruct the function to shuffle a playlist that has already been shuffled,
  /// YouTube will shuffle the order again.
  void setShuffle({required bool shufflePlaylists});

  /// This getter retrieves the playback rate of the currently playing video.
  /// The default playback rate is 1, which indicates that the video is playing at normal speed.
  ///
  /// Playback rates may include values like 0.25, 0.5, 1, 1.5, and 2.
  Future<double> get playbackRate;

  /// This function returns the set of playback rates in which the current video is available.
  /// The default value is 1, which indicates that the video is playing in normal speed.
  ///
  /// The function returns an array of numbers ordered from slowest to fastest playback speed.
  /// Even if the player does not support variable playback speeds, the array should always contain at least one value (1).
  Future<List<double>> get availablePlaybackRates;
}
