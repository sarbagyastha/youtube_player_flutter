extension DurationFormatter on Duration {
  /// Formats as `MM:SS` or `H:MM:SS` when >= 1 hour.
  String toHhMmSs() {
    final h = inHours;
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
