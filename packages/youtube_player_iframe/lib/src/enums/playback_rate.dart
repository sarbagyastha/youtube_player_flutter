// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Playback rate or speed for the video.
///
/// Find more about it [here](https://developers.google.com/youtube/iframe_api_reference#getPlaybackRate).
class PlaybackRate {
  /// Sets playback rate to 2.0 times.
  static const double twice = 2.0;

  /// Sets playback rate to 1.75 times.
  static const double oneAndAThreeQuarter = 1.75;

  /// Sets playback rate to 1.5 times.
  static const double oneAndAHalf = 1.5;

  /// Sets playback rate to 1.25 times.
  static const double oneAndAQuarter = 1.25;

  /// Sets playback rate to 1.0 times.
  static const double normal = 1.0;

  /// Sets playback rate to 0.75 times.
  static const double threeQuarter = 0.75;

  /// Sets playback rate to 0.5 times.
  static const double half = 0.5;

  /// Sets playback rate to 0.25 times.
  static const double quarter = 0.25;

  /// All
  static const List<double> all = [
    twice,
    oneAndAThreeQuarter,
    oneAndAHalf,
    oneAndAQuarter,
    normal,
    threeQuarter,
    half,
    quarter,
  ];
}
