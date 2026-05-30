// Copyright 2024 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../controller/youtube_player_controller.dart';
import '../enums/player_state.dart';
import '../enums/thumbnail_format.dart';
import '../player_value.dart';
import '../enums/thumbnail_quality.dart';
import 'youtube_player.dart';

/// A widget that shows a YouTube video thumbnail and loads the player in-place
/// when tapped.
///
/// This is more performant than embedding [YoutubePlayer] directly in a list,
/// since the WebView is only created after the user taps.
///
/// ```dart
/// YoutubePlayerThumbnail(
///   controller: YoutubePlayerController.fromVideoId(videoId: 'dQw4w9WgXcQ'),
/// )
/// ```
class YoutubePlayerThumbnail extends StatefulWidget {
  /// Creates a [YoutubePlayerThumbnail].
  const YoutubePlayerThumbnail({
    super.key,
    required this.controller,
    this.aspectRatio = 16 / 9,
    this.thumbnailQuality = .high,
    this.thumbnailFormat = .webp,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.backgroundColor,
    this.enableFullScreenOnVerticalDrag = true,
    this.autoFullScreen = true,
    this.playIcon,
  });

  /// The controller for the player.
  final YoutubePlayerController controller;

  /// Aspect ratio for the player and thumbnail.
  ///
  /// Defaults to 16/9.
  final double aspectRatio;

  /// Quality of the thumbnail image.
  ///
  /// Defaults to [ThumbnailQuality.high].
  final ThumbnailQuality thumbnailQuality;

  /// Format of the thumbnail image.
  ///
  /// Defaults to [ThumbnailFormat.webp].
  final ThumbnailFormat thumbnailFormat;

  /// Which gestures should be consumed by the youtube player once active.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// The background color of the [YoutubePlayer].
  final Color? backgroundColor;

  /// Enables switching to full screen on vertical drag in the player.
  ///
  /// Defaults to true.
  final bool enableFullScreenOnVerticalDrag;

  /// Whether to automatically enter fullscreen when the device rotates to
  /// landscape while the player is active.
  ///
  /// Defaults to true.
  final bool autoFullScreen;

  /// Widget shown in the center of the thumbnail as the play button.
  ///
  /// Defaults to a red circular play button.
  final Widget? playIcon;

  @override
  State<YoutubePlayerThumbnail> createState() => _YoutubePlayerThumbnailState();
}

class _YoutubePlayerThumbnailState extends State<YoutubePlayerThumbnail> {
  bool _playerActive = false;
  StreamSubscription<YoutubePlayerValue>? _playSubscription;

  void _activate() {
    setState(() => _playerActive = true);
    _playSubscription = widget.controller.stream.listen((value) {
      if (value.playerState == PlayerState.cued) {
        _playSubscription?.cancel();
        _playSubscription = null;
        widget.controller.playVideo();
      }
    });
  }

  @override
  void dispose() {
    _playSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_playerActive) {
      return YoutubePlayer(
        controller: widget.controller,
        aspectRatio: widget.aspectRatio,
        gestureRecognizers: widget.gestureRecognizers,
        backgroundColor: widget.backgroundColor,
        enableFullScreenOnVerticalDrag: widget.enableFullScreenOnVerticalDrag,
        autoFullScreen: widget.autoFullScreen,
      );
    }

    final videoId = widget.controller.key;

    return GestureDetector(
      onTap: () {
        widget.controller.playVideo();
        _activate();
      },
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (videoId != null)
              Image.network(
                YoutubePlayerController.getThumbnail(
                  videoId: videoId,
                  quality: widget.thumbnailQuality,
                  format: widget.thumbnailFormat,
                ),
                webHtmlElementStrategy: .prefer,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : ColoredBox(color: Theme.of(context).colorScheme.surface),
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: Theme.of(context).colorScheme.surface),
              )
            else
              ColoredBox(color: Theme.of(context).colorScheme.surface),
            Center(child: widget.playIcon ?? const _DefaultPlayIcon()),
          ],
        ),
      ),
    );
  }
}

class _DefaultPlayIcon extends StatelessWidget {
  const _DefaultPlayIcon();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(Icons.play_arrow, color: colorScheme.onPrimary, size: 32),
      ),
    );
  }
}
