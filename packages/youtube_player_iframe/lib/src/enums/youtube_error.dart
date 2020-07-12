// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Youtube Errors
enum YoutubeError {
  /// Error Free
  none,

  /// The request contains an invalid parameter value.
  ///
  /// For example, this error occurs if you specify a video ID that does not have 11 characters,
  /// or if the video ID contains invalid characters, such as exclamation points or asterisks.
  invalid_param,

  /// The requested content cannot be played in an HTML5 player or another error related to the HTML5 player has occurred.
  html5_error,

  /// The video requested was not found. This error occurs when a video has been removed (for any reason) or has been marked as private.
  video_not_found,

  /// The owner of the requested video does not allow it to be played in embedded players.
  not_embeddable,

  /// The requested video couldn't be found.
  cannot_find_video,

  /// This error is the same as [YoutubeError.not_embeddable] in disguise!
  same_as_not_embeddable,

  /// Unknown Error
  unknown,
}

///
YoutubeError errorEnum(int errorCode) {
  switch (errorCode) {
    case 2:
      return YoutubeError.invalid_param;
    case 5:
      return YoutubeError.html5_error;
    case 100:
      return YoutubeError.video_not_found;
    case 101:
      return YoutubeError.not_embeddable;
    case 105:
      return YoutubeError.cannot_find_video;
    case 150:
      return YoutubeError.same_as_not_embeddable;
    default:
      return YoutubeError.unknown;
  }
}
