// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Metadata for the currently loaded video. Fields are empty or zero until a video loads.
class YoutubeMetaData {
  final String videoId;
  final String title;
  final String author;
  final Duration duration;

  const YoutubeMetaData({
    this.videoId = '',
    this.title = '',
    this.author = '',
    this.duration = const Duration(),
  });

  /// Returns a copy of this meta data with the given fields replaced.
  YoutubeMetaData copyWith({
    String? videoId,
    String? title,
    String? author,
    Duration? duration,
  }) {
    return YoutubeMetaData(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      author: author ?? this.author,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is YoutubeMetaData &&
            runtimeType == other.runtimeType &&
            videoId == other.videoId &&
            title == other.title &&
            author == other.author &&
            duration == other.duration;
  }

  @override
  int get hashCode => Object.hash(videoId, title, author, duration);

  @override
  String toString() {
    return 'YoutubeMetaData('
        'videoId: $videoId, '
        'title: $title, '
        'author: $author, '
        'duration: ${duration.inSeconds} sec.)';
  }
}
