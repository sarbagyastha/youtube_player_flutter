// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ThumbnailCard extends StatelessWidget {
  const ThumbnailCard({
    super.key,
    required this.videoId,
    required this.selected,
  });

  final String videoId;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(30);

    return Material(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            YoutubePlayerController.getThumbnail(
              videoId: videoId,
              quality: .high,
            ),
            fit: BoxFit.fitWidth,
            webHtmlElementStrategy: .fallback,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Colors.black12,
              child: Icon(Icons.ondemand_video, color: Colors.white54),
            ),
          ),
          if (selected)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 3),
                borderRadius: borderRadius,
                color: colorScheme.primary.withValues(alpha: 0.4),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: colorScheme.onPrimary,
                  size: 36,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
