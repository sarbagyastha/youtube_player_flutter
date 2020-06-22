// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Converts error code into pre-defined error messages.
String errorString(int errorCode, {String videoId = ''}) {
  switch (errorCode) {
    case 1:
      return 'Invalid Video ID = $videoId';
    case 2:
      return 'The request contains an invalid parameter value.';
    case 5:
      return 'The requested content cannot be played by the player.';
    case 100:
      return 'The video requested was not found.';
    case 101:
      return 'Playback on other apps has been disabled by the video owner.';
    case 105:
      return 'Exact error cannot be determined for this video.';
    case 150:
      return 'Playback on other apps has been disabled by the video owner.';
    default:
      return 'Unknown Error';
  }
}
