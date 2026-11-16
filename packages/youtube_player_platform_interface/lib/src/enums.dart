// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Playback state of the player, as reported by `onStateChange`.
///
/// See https://developers.google.com/youtube/iframe_api_reference#Playback_status
enum PlayerState(
  /// The raw code used by the IFrame API.
  final int code,
) {
  /// No state has been reported yet.
  unknown(-2),

  /// The player has loaded a video but playback has not started.
  unStarted(-1),

  /// Playback has finished.
  ended(0),

  /// The video is playing.
  playing(1),

  /// The video is paused.
  paused(2),

  /// The player is buffering.
  buffering(3),

  /// A video is cued and ready to play.
  cued(5);

  /// Returns the [PlayerState] for [code], or [unknown] when unrecognised.
  static PlayerState fromCode(int code) => switch (code) {
    -1 => .unStarted,
    0 => .ended,
    1 => .playing,
    2 => .paused,
    3 => .buffering,
    5 => .cued,
    _ => .unknown,
  };

  /// Whether the media clock is advancing (or about to).
  bool get isActive => this == .playing || this == .buffering;
}

/// Errors reported by the IFrame API `onError` event.
///
/// See https://developers.google.com/youtube/iframe_api_reference#onError
enum YoutubeError(
  /// The primary raw code used by the IFrame API.
  final int code,
) {
  /// No error.
  none(0),

  /// The request contains an invalid parameter value, e.g. a malformed video id.
  invalidParam(2),

  /// The content cannot be played in an HTML5 player.
  html5Error(5),

  /// The video was removed or is private.
  videoNotFound(100),

  /// The owner does not allow embedded playback (codes 101, 150 and 152).
  notEmbeddable(101),

  /// The embed request did not identify the client (no HTTP Referer).
  ///
  /// The plugin sets the client identity automatically; if this occurs, check
  /// `YoutubePlayerParams.appId`.
  missingClientIdentity(153),

  /// An unrecognised error code.
  unknown(-1);

  /// Returns the [YoutubeError] for [code], or [unknown] when unrecognised.
  static YoutubeError fromCode(int code) => switch (code) {
    0 => .none,
    2 => .invalidParam,
    5 => .html5Error,
    100 => .videoNotFound,
    101 || 150 || 152 => .notEmbeddable,
    153 => .missingClientIdentity,
    _ => .unknown,
  };
}

/// What Android does with the screen orientation while the WebView presents a
/// video fullscreen. Other platforms follow the system behavior.
enum FullscreenOrientation {
  /// Rotate to landscape (sensor-driven) while fullscreen.
  landscape,

  /// Follow the device sensor freely while fullscreen.
  auto,

  /// Keep whatever orientation the app currently has.
  unchanged,
}

/// Every IFrame API function the plugin calls, plus page-level helpers.
///
/// [returnsValue] marks calls whose result is sent back to Dart. All other
/// calls are fire-and-forget to keep the channel quiet.
enum PlayerMethod({
  /// Whether the page replies with a value for this call.
  final bool returnsValue = false,
}) {
  // Queueing
  /// `cueVideoById({videoId, startSeconds, endSeconds})`
  cueVideoById,

  /// `loadVideoById({videoId, startSeconds, endSeconds})`
  loadVideoById,

  /// `cueVideoByUrl({mediaContentUrl, startSeconds, endSeconds})`
  cueVideoByUrl,

  /// `loadVideoByUrl({mediaContentUrl, startSeconds, endSeconds})`
  loadVideoByUrl,

  /// `cuePlaylist({listType, list, index, startSeconds})`
  cuePlaylist,

  /// `loadPlaylist({listType, list, index, startSeconds})`
  loadPlaylist,

  // Playback
  /// `playVideo()`
  playVideo,

  /// `pauseVideo()`
  pauseVideo,

  /// `stopVideo()`
  stopVideo,

  /// `seekTo(seconds, allowSeekAhead)`
  seekTo,

  /// `nextVideo()`
  nextVideo,

  /// `previousVideo()`
  previousVideo,

  /// `playVideoAt(index)`
  playVideoAt,

  // Volume
  /// `mute()`
  mute,

  /// `unMute()`
  unMute,

  /// `setVolume(volume)`
  setVolume,

  // Size, rate, playlist behaviour
  /// `setSize(width, height)`
  setSize,

  /// `setPlaybackRate(suggestedRate)`
  setPlaybackRate,

  /// `getAvailablePlaybackRates()`
  getAvailablePlaybackRates(returnsValue: true),

  /// `setLoop(loopPlaylists)`
  setLoop,

  /// `setShuffle(shufflePlaylist)`
  setShuffle,

  // Information
  /// `getVideoUrl()`
  getVideoUrl(returnsValue: true),

  /// `getVideoEmbedCode()`
  getVideoEmbedCode(returnsValue: true),

  /// `getPlaylist()`
  getPlaylist(returnsValue: true),

  /// `getPlaylistIndex()`
  getPlaylistIndex(returnsValue: true),

  // Modules
  /// `getOptions(module?)`
  getOptions(returnsValue: true),

  /// `getOption(module, option)`
  getOption(returnsValue: true),

  /// `setOption(module, option, value)`
  setOption,

  // 360°
  /// `getSphericalProperties()`
  getSphericalProperties(returnsValue: true),

  /// `setSphericalProperties(properties)`
  setSphericalProperties,

  // Page helpers (not IFrame API functions)
  /// Requests element fullscreen for the player container. Resolves to
  /// whether the request was accepted.
  requestFullscreen(returnsValue: true),

  /// Exits element fullscreen.
  exitFullscreen,

  /// `setHidden(selectors)`: replaces the CSS selectors hidden inside the
  /// player iframe.
  setHidden,

  /// `resolveClick(id, allow)`: replays or drops a held click.
  resolveClick,
}
