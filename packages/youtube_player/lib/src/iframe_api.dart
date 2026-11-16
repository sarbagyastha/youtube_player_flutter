// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

/// Playlist sources accepted by `cuePlaylist` / `loadPlaylist`.
enum ListType(
  /// Wire value.
  final String value,
) {
  /// A playlist id (usually prefixed `PL`).
  playlist('playlist'),

  /// All uploads of a channel / user.
  userUploads('user_uploads'),
}

/// The documented YouTube IFrame Player API functions.
///
/// See https://developers.google.com/youtube/iframe_api_reference#Functions
abstract interface class YoutubePlayerIFrameAPI {
  // Queueing

  /// Loads the thumbnail of [videoId] and prepares the player; playback
  /// starts on `playVideo` or `seekTo`.
  void cueVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  });

  /// Loads and plays [videoId].
  void loadVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  });

  /// Cues a video by its fully qualified player URL
  /// (`https://www.youtube.com/v/VIDEO_ID?version=3`).
  void cueVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  });

  /// Loads and plays a video by its fully qualified player URL.
  void loadVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  });

  /// Cues a playlist: a list of video ids, or a single playlist / channel id
  /// with [listType].
  void cuePlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  });

  /// Loads and plays a playlist; see [cuePlaylist].
  void loadPlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  });

  // Playback

  /// Plays the current video.
  void playVideo();

  /// Pauses the current video.
  void pauseVideo();

  /// Stops loading the current video. Prefer [pauseVideo] for pausing.
  void stopVideo();

  /// Seeks to [seconds]. Use `allowSeekAhead: false` while scrubbing and
  /// `true` on release.
  void seekTo({required double seconds, bool allowSeekAhead = false});

  /// Next video in the playlist.
  void nextVideo();

  /// Previous video in the playlist.
  void previousVideo();

  /// Plays the playlist video at [index] (zero-based).
  void playVideoAt(int index);

  // Volume

  /// Mutes the player.
  void mute();

  /// Unmutes the player.
  void unMute();

  /// Whether the player is muted.
  bool get isMuted;

  /// Sets the volume, `0..100`.
  void setVolume(int volume);

  /// Volume `0..100`, even while muted.
  int get volume;

  // Size, rate and playlist behaviour

  /// Sets the iframe size in CSS pixels. Rarely needed: the player fills its
  /// widget.
  void setSize(double width, double height);

  /// Current playback rate.
  double get playbackRate;

  /// Suggests a playback rate. Watch `value.playbackRate` for the result;
  /// unsupported rates round towards 1.
  void setPlaybackRate(double suggestedRate);

  /// Rates supported by the current video, slowest first.
  Future<List<double>> get availablePlaybackRates;

  /// Whether playlists loop. Persists across playlist loads.
  void setLoop({required bool loopPlaylists});

  /// Whether playlists shuffle. Does not persist across playlist loads.
  void setShuffle({required bool shufflePlaylists});

  // Status and information

  /// Playback state.
  PlayerState get playerState;

  /// Seconds elapsed.
  double get currentTime;

  /// Buffered fraction, `0..1`.
  double get videoLoadedFraction;

  /// Duration in seconds (0 until metadata loads).
  double get duration;

  /// youtube.com URL of the current video.
  Future<String> get videoUrl;

  /// Best-effort id / title / author of the current video.
  VideoData get videoData;

  /// Embed code of the current video.
  Future<String> get videoEmbedCode;

  /// Video ids of the current playlist, in play order.
  Future<List<String>> get playlist;

  /// Index of the current playlist video.
  Future<int> get playlistIndex;

  // Modules and 360°

  /// Caption font size step, `-1..3` (`captions.fontSize`).
  void setCaptionsFontSize(int size);

  /// Reloads caption data (`captions.reload`).
  void reloadCaptions();

  /// Option names exposed by [module] (or module names when null).
  Future<List<String>> getOptions([String? module]);

  /// Current view of a 360° video; empty for regular videos.
  Future<SphericalProperties> get sphericalProperties;

  /// Updates the view of a 360° video.
  void setSphericalProperties(SphericalProperties properties);
}
