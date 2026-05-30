// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Quality of YouTube video thumbnail.
enum ThumbnailQuality {
  /// 120x90
  defaultQuality('default'),

  /// 320x180
  medium('mqdefault'),

  /// 480x360
  high('hqdefault'),

  /// 640x480
  standard('sddefault'),

  /// Unscaled thumbnail
  max('maxresdefault');

  const ThumbnailQuality(this.value);

  /// The YouTube thumbnail quality identifier.
  final String value;
}
