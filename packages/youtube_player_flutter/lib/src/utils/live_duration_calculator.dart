import '../../youtube_player_flutter.dart';

/// Calculator used to determine the livestreams values for stream metadata
/// Livestreams must increment their times based on the difference between
/// when they were started and how long the stream has been running in
/// the YouTube player.
class LiveDurationCalculator {
  static LivestreamTimes getDuration({
    /// The controller of the livestream
    required YoutubePlayerController controller,

    /// The time milliseconds selected by the livestream player
    required int selectedTimeMs,
  }) {
    final offset = controller.metadata.totalVideoLengthMs -
        controller.metadata.startingVideoLengthMs;
    final positionMs = selectedTimeMs + offset;
    final totalVideoTimeMs = controller.metadata.totalVideoLengthMs;

    final durationMs = controller.value.metaData.duration.inMilliseconds;
    final streamAtMaxTime = maxDurationMs <= durationMs;

    return LivestreamTimes(
        selectedPositionMs: positionMs,
        videoDurationMs: streamAtMaxTime ? maxDurationMs : durationMs,
        totalVideoTimeMs: totalVideoTimeMs);
  }
}

/// Wrapper class to hold formatted times for livestreams
class LivestreamTimes {
  final int videoDurationMs;
  final int selectedPositionMs;
  final int totalVideoTimeMs;

  const LivestreamTimes({
    required this.videoDurationMs,
    required this.selectedPositionMs,
    required this.totalVideoTimeMs,
  });
}
