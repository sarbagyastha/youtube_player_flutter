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
    final startTime = controller.metadata.startTime;
    assert(startTime != null, 'Start time must be specified for livestreams');
    final timeOffset = DateTime.now().difference(startTime!).inMilliseconds;

    final positionMs = selectedTimeMs + timeOffset;
    final totalVideoTimeMs =
        controller.metadata.totalVideoLengthMs + timeOffset;

    final streamAtMaxTime =
        maxDurationMs <= controller.value.metaData.duration.inMilliseconds;

    if (streamAtMaxTime) {
      //Stream is max length, no need to offset duration
      return LivestreamTimes(
          selectedPositionMs: positionMs,
          videoDurationMs: maxDurationMs,
          totalVideoTimeMs: totalVideoTimeMs);
    }

    final durationMs =
        controller.value.metaData.duration.inMilliseconds + timeOffset;

    if (durationMs >= maxDurationMs) {
      final metadata = controller.metadata.copyWith(
          duration: const Duration(milliseconds: maxDurationMs),
          totalVideoLengthMs: totalVideoTimeMs);

      controller.updateValue(YoutubePlayerValue(metaData: metadata));
      return LivestreamTimes(
          selectedPositionMs: positionMs,
          videoDurationMs: maxDurationMs,
          totalVideoTimeMs: totalVideoTimeMs);
    }

    final actualDurationMs =
        durationMs >= maxDurationMs ? maxDurationMs : durationMs;

    return LivestreamTimes(
        selectedPositionMs: positionMs,
        videoDurationMs: actualDurationMs,
        totalVideoTimeMs: totalVideoTimeMs);
  }
}

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
