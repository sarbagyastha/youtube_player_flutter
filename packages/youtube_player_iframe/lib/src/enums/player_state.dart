// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Current state of the player.
///
/// Find more about it [here](https://developers.google.com/youtube/iframe_api_reference#Playback_status).
enum PlayerState {
  /// No video has been loaded. Initial state.
  unknown(-2),

  /// Player is ready but playback has not started.
  unStarted(-1),

  /// Playback has finished.
  ended(0),

  /// Video is playing.
  playing(1),

  /// Video is paused.
  paused(2),

  /// Buffering. Show a loading indicator.
  buffering(3),

  /// A video is loaded and ready, but autoPlay is false.
  cued(5);

  const PlayerState(this.code);

  /// The raw code returned by the YouTube IFrame API.
  final int code;
}
