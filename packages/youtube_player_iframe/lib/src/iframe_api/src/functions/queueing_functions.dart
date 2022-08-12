/// Queueing functions allow you to load and play a video, a playlist, or another list of videos.
/// If you are using the object syntax described below to call these functions,
/// then you can also queue or load a list of a user's uploaded videos.
abstract class QueueingFunctions {
  /// This function loads the specified video's thumbnail and prepares the player to play the video.
  /// The player does not request the FLV until [playVideo] or [seekTo] is called.
  ///
  /// [videoId] specifies the YouTube Video ID of the video to be played.
  /// In the YouTube Data API, a video resource's id property specifies the ID.
  ///
  /// [startSeconds] specifies the time from which the video should start playing when [playVideo] is called.
  /// If you specify a startSeconds value and then call [seekTo], then the player plays from the time specified in the seekTo() call.
  /// When the video is cued and ready to play, the player will broadcast a video cued event (5).
  ///
  /// [endSeconds] specifies the time when the video should stop playing when playVideo() is called.
  /// If you specify an endSeconds value and then call seekTo(), the endSeconds value will no longer be in effect.
  Future<void> cueVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  });

  /// This function loads and plays the specified video.
  ///
  /// [videoId] specifies the YouTube Video ID of the video to be played.
  /// In the YouTube Data API, a video resource's id property specifies the ID.
  ///
  /// [startSeconds], if specified, then the video will start from the closest keyframe to the specified time.
  ///
  /// [endSeconds], if specified, then the video will stop playing at the specified time.
  Future<void> loadVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  });

  /// This function loads the specified video's thumbnail and prepares the player to play the video.
  /// The player does not request the FLV until [playVideo] or [seekTo] is called.
  ///
  /// [mediaContentUrl] specifies a fully qualified YouTube player URL in the format
  /// http://www.youtube.com/v/VIDEO_ID?version=3.
  ///
  /// [startSeconds] specifies the time from which the video should start playing when playVideo() is called.
  /// If you specify startSeconds and then call seekTo(), then the player plays from the time specified in the seekTo() call.
  /// When the video is cued and ready to play, the player will broadcast a video cued event (5).
  ///
  /// [endSeconds] specifies the time when the video should stop playing when playVideo() is called.
  /// If you specify an endSeconds value and then call seekTo(), the endSeconds value will no longer be in effect.
  Future<void> cueVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  });

  /// This function loads and plays the specified video.
  ///
  /// [mediaContentUrl] specifies a fully qualified YouTube player URL in the format
  /// http://www.youtube.com/v/VIDEO_ID?version=3.
  ///
  /// [startSeconds] specifies the time from which the video should start playing.
  /// If startSeconds is specified, the video will start from the closest keyframe to the specified time.
  ///
  /// [endSeconds] specifies the time when the video should stop playing.
  Future<void> loadVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  });

  /// Queues the specified list of videos.
  /// The list can be a playlist or a user's uploaded videos feed.
  ///
  /// When the list is cued and ready to play, the player will broadcast a video cued event (5).
  ///
  /// [list] contains a key that identifies the particular list of videos that YouTube should return.
  ///
  /// [listType] specifies the type of results feed that you are retrieving.
  ///
  /// [index] specifies the index of the first video in the list that will play.
  /// The parameter uses a zero-based index, and the default parameter value is 0,
  /// so the default behavior is to load and play the first video in the list.
  ///
  /// [startSeconds] specifies the time from which the first video in the list
  /// should start playing when the [playVideo] function is called.
  /// If you specify a startSeconds value and then call [seekTo], then the player plays from the time specified in the seekTo() call.
  /// If you cue a list and then call the [playVideoAt] function, the player will start playing at the beginning of the specified video.
  Future<void> cuePlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  });

  /// This function loads the specified list and plays it.
  /// The list can be a playlist or a user's uploaded videos feed.
  ///
  /// [list] contains a key that identifies the particular list of videos that YouTube should return.
  ///
  /// [listType] specifies the type of results feed that you are retrieving.
  ///
  /// [index] specifies the index of the first video in the list that will play.
  /// The parameter uses a zero-based index, and the default parameter value is 0,
  /// so the default behavior is to load and play the first video in the list.
  ///
  /// [startSeconds] specifies the time from which the first video in the list should start playing.
  Future<void> loadPlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  });
}

/// The type of playlist.
enum ListType {
  /// The list specifies the playlist ID or an array of video IDs.
  /// In the YouTube Data API, the playlist resource's id property identifies a playlist's ID,
  /// and the video resource's id property specifies a video ID.
  playlist('playlist'),

  /// The list identifies the user whose uploaded videos will be returned.
  userUploads('user_uploads');

  /// The type of playlist.
  const ListType(this.value);

  /// The actual value of the type.
  final String value;
}
