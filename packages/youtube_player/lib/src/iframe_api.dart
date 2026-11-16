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
  Future<void> cueVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  });

  /// Loads and plays [videoId].
  Future<void> loadVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  });

  /// Cues a video by its fully qualified player URL
  /// (`https://www.youtube.com/v/VIDEO_ID?version=3`).
  Future<void> cueVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  });

  /// Loads and plays a video by its fully qualified player URL.
  Future<void> loadVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  });

  /// Cues a playlist: a list of video ids, or a single playlist / channel id
  /// with [listType].
  Future<void> cuePlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  });

  /// Loads and plays a playlist; see [cuePlaylist].
  Future<void> loadPlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  });

  // Playback

  /// Plays the current video.
  Future<void> playVideo();

  /// Pauses the current video.
  Future<void> pauseVideo();

  /// Stops loading the current video. Prefer [pauseVideo] for pausing.
  Future<void> stopVideo();

  /// Seeks to [seconds]. Use `allowSeekAhead: false` while scrubbing and
  /// `true` on release.
  Future<void> seekTo({required double seconds, bool allowSeekAhead = false});

  /// Next video in the playlist.
  Future<void> nextVideo();

  /// Previous video in the playlist.
  Future<void> previousVideo();

  /// Plays the playlist video at [index] (zero-based).
  Future<void> playVideoAt(int index);

  // Volume

  /// Mutes the player.
  Future<void> mute();

  /// Unmutes the player.
  Future<void> unMute();

  /// Whether the player is muted.
  Future<bool> get isMuted;

  /// Sets the volume, `0..100`.
  Future<void> setVolume(int volume);

  /// Volume `0..100`, even while muted.
  Future<int> get volume;

  // Size, rate and playlist behaviour

  /// Sets the iframe size in CSS pixels. Rarely needed: the player fills its
  /// widget.
  Future<void> setSize(double width, double height);

  /// Current playback rate.
  Future<double> get playbackRate;

  /// Suggests a playback rate. Watch `value.playbackRate` for the result;
  /// unsupported rates round towards 1.
  Future<void> setPlaybackRate(double suggestedRate);

  /// Rates supported by the current video, slowest first.
  Future<List<double>> get availablePlaybackRates;

  /// Whether playlists loop. Persists across playlist loads.
  Future<void> setLoop({required bool loopPlaylists});

  /// Whether playlists shuffle. Does not persist across playlist loads.
  Future<void> setShuffle({required bool shufflePlaylists});

  // Status and information

  /// Playback state.
  Future<PlayerState> get playerState;

  /// Seconds elapsed.
  Future<double> get currentTime;

  /// Buffered fraction, `0..1`.
  Future<double> get videoLoadedFraction;

  /// Duration in seconds (0 until metadata loads).
  Future<double> get duration;

  /// youtube.com URL of the current video.
  Future<String> get videoUrl;

  /// Best-effort id / title / author of the current video.
  Future<VideoData> get videoData;

  /// Embed code of the current video.
  Future<String> get videoEmbedCode;

  /// Video ids of the current playlist, in play order.
  Future<List<String>> get playlist;

  /// Index of the current playlist video.
  Future<int> get playlistIndex;

  // Modules and 360°

  /// Caption font size step, `-1..3` (`captions.fontSize`).
  Future<void> setCaptionsFontSize(int size);

  /// Reloads caption data (`captions.reload`).
  Future<void> reloadCaptions();

  /// Option names exposed by [module] (or module names when null).
  Future<List<String>> getOptions([String? module]);

  /// Current view of a 360° video; empty for regular videos.
  Future<SphericalProperties> get sphericalProperties;

  /// Updates the view of a 360° video.
  Future<void> setSphericalProperties(SphericalProperties properties);
}
