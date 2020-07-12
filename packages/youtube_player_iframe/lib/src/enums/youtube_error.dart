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
  invalidParam,

  /// The requested content cannot be played in an HTML5 player or another error related to the HTML5 player has occurred.
  html5Error,

  /// The video requested was not found. This error occurs when a video has been removed (for any reason) or has been marked as private.
  videoNotFound,

  /// The owner of the requested video does not allow it to be played in embedded players.
  notEmbeddable,

  /// The requested video couldn't be found.
  cannotFindVideo,

  /// This error is the same as [YoutubeError.notEmbeddable] in disguise!
  sameAsNotEmbeddable,

  /// Unknown Error
  unknown,
}

///
YoutubeError errorEnum(int errorCode) {
  switch (errorCode) {
    case 2:
      return YoutubeError.invalidParam;
    case 5:
      return YoutubeError.html5Error;
    case 100:
      return YoutubeError.videoNotFound;
    case 101:
      return YoutubeError.notEmbeddable;
    case 105:
      return YoutubeError.cannotFindVideo;
    case 150:
      return YoutubeError.sameAsNotEmbeddable;
    default:
      return YoutubeError.unknown;
  }
}
