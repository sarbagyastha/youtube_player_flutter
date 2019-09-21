/// Playback Rate or Speed for the video.
enum PlaybackRate {
  double,
  one_and_a_three_quarter,
  one_and_a_half,
  one_and_a_quarter,
  normal,
  three_quarter,
  half,
  quarter,
}

Map<PlaybackRate, double> playbackRateMap = {
  PlaybackRate.double: 2.0,
  PlaybackRate.one_and_a_three_quarter: 1.75,
  PlaybackRate.one_and_a_half: 1.5,
  PlaybackRate.one_and_a_quarter: 1.25,
  PlaybackRate.normal: 1.0,
  PlaybackRate.three_quarter: 0.75,
  PlaybackRate.half: 0.5,
  PlaybackRate.quarter: 0.25,
};
