/// Meta data for Youtube Video.
class YoutubeMetaData {
  /// Youtube video ID of the currently loaded video.
  final String videoId;

  /// Video title of the currently loaded video.
  final String title;

  /// Channel name or uploader of the currently loaded video.
  final String author;

  /// Total duration of the currently loaded video.
  final Duration duration;

  /// Creates [YoutubeMetaData] for Youtube Video.
  const YoutubeMetaData({
    this.videoId = '',
    this.title = '',
    this.author = '',
    this.duration = const Duration(),
  });

  /// Creates [YoutubeMetaData] from raw json video data.
  factory YoutubeMetaData.fromRawData(dynamic rawData) {
    final data = rawData as Map<String, dynamic>;
    final durationInMs = (((data['duration'] ?? 0) as double) * 1000).floor();
    return YoutubeMetaData(
      videoId: data['videoId'],
      title: data['title'],
      author: data['author'],
      duration: Duration(milliseconds: durationInMs),
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'videoId: $videoId, '
        'title: $title, '
        'author: $author, '
        'duration: ${duration.inSeconds} sec.)';
  }
}
