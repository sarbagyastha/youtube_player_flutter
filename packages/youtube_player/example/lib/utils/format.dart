/// Formats [duration] as `m:ss`, or `h:mm:ss` from one hour.
String formatDuration(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return hours > 0
      ? '$hours:${two(minutes)}:${two(seconds)}'
      : '$minutes:${two(seconds)}';
}

/// Formats a playback [rate] as `1×`, `1.5×`.
String formatRate(double rate) =>
    '${rate == rate.roundToDouble() ? rate.toInt() : rate}×';

/// Converts fractional [seconds] to a [Duration].
Duration secondsToDuration(double seconds) =>
    Duration(milliseconds: (seconds * 1000).round());
