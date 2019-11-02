// Copyright 2019 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Current state of the player.
///
/// Find more about it [here](https://developers.google.com/youtube/iframe_api_reference#Playback_status).
enum PlayerState {
  unknown,
  unStarted,
  ended,
  playing,
  paused,
  buffering,
  cued,
  stopped,
}
