// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Current state of the player.
///
/// Find more about it [here](https://developers.google.com/youtube/iframe_api_reference#Playback_status).
enum PlayerState {
  /// Denotes State when player is not loaded with video.
  unknown(-2),

  /// Denotes state when player loads first video.
  unStarted(-1),

  /// Denotes state when player has ended playing a video.
  ended(0),

  /// Denotes state when player is playing video.
  playing(1),

  /// Denotes state when player is paused.
  paused(2),

  /// Denotes state when player is buffering bytes from the internet.
  buffering(3),

  /// Denotes state when player loads video and is ready to be played.
  cued(5);

  /// Returns the [PlayerState] from the given code.
  const PlayerState(this.code);

  /// Code of the player state.
  final int code;
}
