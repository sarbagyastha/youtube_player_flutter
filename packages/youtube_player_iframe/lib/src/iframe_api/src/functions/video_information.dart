abstract class VideoInformation {
  Future<double> get duration;

  Future<String> get videoUrl;

  Future<VideoData> get videoData;

  Future<double> get videoEmbedCode;

  Future<List<String>> get playlist;

  Future<int> get playlistIndex;
}

class VideoData {
  VideoData({
    required this.videoId,
    required this.author,
    required this.title,
    required this.videoQuality,
    required this.videoQualityFeatures,
  });

  final String videoId;
  final String author;
  final String title;
  final String videoQuality;
  final List<Object> videoQualityFeatures;

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
