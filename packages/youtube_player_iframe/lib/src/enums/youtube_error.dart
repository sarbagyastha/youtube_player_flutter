// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Youtube Errors
enum YoutubeError {
  /// Error Free
  none(0),

  /// The request contains an invalid parameter value.
  ///
  /// For example, this error occurs if you specify a video ID that does not have 11 characters,
  /// or if the video ID contains invalid characters, such as exclamation points or asterisks.
  invalidParam(2),

  /// The requested content cannot be played in an HTML5 player or another error related to the HTML5 player has occurred.
  html5Error(5),

  /// The video requested was not found. This error occurs when a video has been removed (for any reason) or has been marked as private.
  videoNotFound(100),

  /// The owner of the requested video does not allow it to be played in embedded players.
  notEmbeddable(101),

  /// The requested video couldn't be found.
  cannotFindVideo(105),

  /// This error is the same as [YoutubeError.notEmbeddable] in disguise!
  sameAsNotEmbeddable(150),

  /// Unknown Error
  unknown(-1);

  /// Returns the [YoutubeError] from the given code.
  const YoutubeError(this.code);

  /// Code of the error.
  final int code;
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
