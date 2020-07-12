// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Specifies the type of results feed that you are retrieving when loading or cueing playlist.
///
/// More info [here](https://developers.google.com/youtube/iframe_api_reference#loadPlaylist)
class PlaylistType {
  /// Playlist ID
  static const String playlist = 'playlist';

  /// Search Query
  static const String search = 'search';

  /// Channel Name
  static const String channel = 'user_uploads';

  /// All
  static const List<String> all = [playlist, search, channel];
}
