import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// The skeleton for video information getters.
abstract class VideoInformation {
  /// Returns the duration in seconds of the currently playing video.
  /// Note that [duration] will return 0 until the video's metadata is loaded,
  /// which normally happens just after the video starts playing.
  ///
  /// If the currently playing video is a live event,
  /// the [duration] will return the elapsed time since the live video stream began.
  /// Specifically, this is the amount of time that the video has streamed without being reset or interrupted.
  /// In addition, this duration is commonly longer than the actual event time since streaming may begin before the event's start time.
  Future<double> get duration;

  /// Returns the YouTube.com URL for the currently loaded/playing video.
  Future<String> get videoUrl;

  /// Returns the [VideoData] for the currently loaded/playing video.
  Future<VideoData> get videoData;

  /// Returns the embed code for the currently loaded/playing video.
  Future<String> get videoEmbedCode;

  /// This function returns an array of the video IDs in the playlist as they are currently ordered.
  /// By default, this function will return video IDs in the order designated by the playlist owner.
  ///
  /// However, if you have called the [YoutubePlayerController.setShuffle] to shuffle the playlist order,
  /// then the return value will reflect the shuffled order.
  Future<List<String>> get playlist;

  /// This function returns the index of the playlist video that is currently playing.
  Future<int> get playlistIndex;
}

/// The video data for the currently playing/loaded video.
class VideoData {
  /// Creates [VideoData].
  const VideoData({
    required this.videoId,
    required this.author,
    required this.title,
    required this.videoQuality,
    required this.videoQualityFeatures,
  });

  /// The YouTube video id for the video.
  final String videoId;

  /// The channel name for the video.
  final String author;

  /// The title of the video.
  final String title;

  /// The playback video quality for the video.
  final String videoQuality;

  /// The video quality features.
  final List<Object> videoQualityFeatures;

  /// Creates [VideoData] from the [map].
  factory VideoData.fromMap(Map<String, dynamic> map) {
    return VideoData(
      videoId: map['video_id'] ?? '',
      author: map['author'] ?? '',
      title: map['title'] ?? '',
      videoQuality: map['videoQuality'] ?? '',
      videoQualityFeatures: List.from(map['videoQualityFeatures'] ?? []),
    );
  }
}
