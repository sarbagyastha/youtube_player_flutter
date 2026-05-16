import 'dart:convert';

/// The current state of the Youtube video.
class YoutubeVideoState {
  /// Creates a new instance of [YoutubeVideoState].
  const YoutubeVideoState({
    this.position = Duration.zero,
    this.loadedFraction = 0,
  });

  /// Creates a new instance of [YoutubeVideoState] from the given [json].
  factory YoutubeVideoState.fromJson(String json) {
    final state = jsonDecode(json);
    final currentTime = state['currentTime'] as num? ?? 0;
    final loadedFraction = state['loadedFraction'] as num? ?? 0;
    final positionInMs = (currentTime * 1000).truncate();

    return YoutubeVideoState(
      position: Duration(milliseconds: positionInMs),
      loadedFraction: loadedFraction.toDouble(),
    );
  }

  /// The current position of the video.
  final Duration position;

  /// The fraction of the video that has been buffered.
  final double loadedFraction;
}
