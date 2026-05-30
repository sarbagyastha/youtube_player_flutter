// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Error codes reported by the YouTube IFrame API.
///
/// Check `YoutubePlayerValue.error`; it is [YoutubeError.none] when there is no error.
enum YoutubeError {
  /// No error.
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

  /// Same restriction as [YoutubeError.notEmbeddable]; YouTube returns code 150.
  sameAsNotEmbeddable(150),

  /// Same restriction as [YoutubeError.notEmbeddable]; YouTube returns code 152.
  sameAsNotEmbeddable2(152),

  /// An unrecognised error code was returned.
  unknown(-1);

  const YoutubeError(this.code);

  /// The raw code returned by the YouTube IFrame API.
  final int code;

  /// Returns the [YoutubeError] matching [code], or [YoutubeError.unknown] if unrecognised.
  static YoutubeError fromCode(int code) => switch (code) {
    0 => .none,
    2 => .invalidParam,
    5 => .html5Error,
    100 => .videoNotFound,
    101 => .notEmbeddable,
    105 => .cannotFindVideo,
    150 => .sameAsNotEmbeddable,
    152 => .sameAsNotEmbeddable2,
    _ => .unknown,
  };
}
