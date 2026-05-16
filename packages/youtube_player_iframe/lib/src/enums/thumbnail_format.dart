// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Format of YouTube video thumbnail.
enum ThumbnailFormat {
  /// WebP format (smaller file size, modern browsers).
  webp('vi_webp', 'webp'),

  /// JPEG format (universal compatibility).
  jpeg('vi', 'jpg');

  const ThumbnailFormat(this._path, this._extension);

  final String _path;
  final String _extension;

  /// Builds the thumbnail URL for [videoId] and [quality].
  String buildUrl(String videoId, String quality) {
    return 'https://i3.ytimg.com/$_path/$videoId/$quality.$_extension';
  }
}
