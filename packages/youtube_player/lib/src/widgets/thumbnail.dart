// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../controller.dart';
import '../value.dart';
import 'youtube_player.dart';

/// A lightweight thumbnail that turns into a [YoutubePlayer] when tapped.
///
/// Nothing is loaded from YouTube until the tap, which keeps long lists cheap.
/// The thumbnail must be at least 120x70 to start playback, per YouTube's
/// Required Minimum Functionality.
class const YoutubePlayerThumbnail({
  super.key,

  /// Controller of the player shown after the tap. Its
  /// [YoutubePlayerController.initialVideoId] (or key) picks the thumbnail.
  required final YoutubePlayerController controller,

  /// Width / height of the thumbnail and player.
  final double aspectRatio = 16 / 9,

  /// Thumbnail size.
  final ThumbnailQuality thumbnailQuality = .high,

  /// Thumbnail format.
  final ThumbnailFormat thumbnailFormat = .webp,

  /// Passed to the [YoutubePlayer].
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers =
      const {},

  /// Background behind the thumbnail and player.
  final Color backgroundColor = const Color(0xFF000000),

  /// Replaces the default play button.
  final Widget? playIcon,
}) extends StatefulWidget {
  @override
  State<YoutubePlayerThumbnail> createState() => _YoutubePlayerThumbnailState();
}

class _YoutubePlayerThumbnailState extends State<YoutubePlayerThumbnail> {
  var _playing = false;

  void _play() {
    setState(() => _playing = true);
    widget.controller.playVideo();
  }

  @override
  Widget build(BuildContext context) {
    if (_playing) {
      return YoutubePlayer(
        controller: widget.controller,
        aspectRatio: widget.aspectRatio,
        gestureRecognizers: widget.gestureRecognizers,
        backgroundColor: widget.backgroundColor,
        thumbnailQuality: widget.thumbnailQuality,
        thumbnailFormat: widget.thumbnailFormat,
        autoPlayWhenVisible: false,
      );
    }
    final videoId =
        widget.controller.initialVideoId ?? widget.controller.key ?? '';
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          assert(
            constraints.maxWidth >= 120 && constraints.maxHeight >= 70,
            'YouTube requires thumbnails that start playback to be at least '
            '120x70; got ${constraints.biggest}.',
          );
          return GestureDetector(
            onTap: _play,
            child: Semantics(
              button: true,
              label: 'Play video',
              child: Stack(
                fit: .expand,
                children: [
                  ColoredBox(color: widget.backgroundColor),
                  if (videoId.isNotEmpty)
                    Image.network(
                      widget.thumbnailFormat.buildUrl(
                        videoId,
                        widget.thumbnailQuality,
                      ),
                      fit: .cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  Center(child: widget.playIcon ?? const _PlayButton()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class const _PlayButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 68,
    height: 48,
    child: CustomPaint(painter: _PlayButtonPainter()),
  );
}

class const _PlayButtonPainter() extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height * 0.28),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFFF0000));
    final w = size.width, h = size.height;
    final triangle = Path()
      ..moveTo(w * 0.40, h * 0.30)
      ..lineTo(w * 0.40, h * 0.70)
      ..lineTo(w * 0.66, h * 0.50)
      ..close();
    canvas.drawPath(triangle, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(_PlayButtonPainter oldDelegate) => false;
}
