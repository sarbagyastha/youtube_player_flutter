// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// One row of the vertical playlist: thumbnail on the left, details on the
/// right, highlighted while it is the current video.
class PlaylistTile extends StatelessWidget {
  const PlaylistTile({
    super.key,
    required this.index,
    required this.videoId,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String videoId;
  final bool selected;
  final VoidCallback onTap;

  static const _thumbWidth = 148.0;
  static const _radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected ? cs.primaryContainer.withValues(alpha: 0.45) : null,
        type: selected ? .canvas : .transparency,
        borderRadius: _radius,
        clipBehavior: .antiAlias,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: Padding(
            padding: const .all(6),
            child: Row(
              children: [
                _Thumbnail(videoId: videoId, selected: selected),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video ${index + 1}',
                        style: tt.titleSmall?.copyWith(
                          color: selected ? cs.primary : cs.onSurface,
                          fontWeight: selected ? FontWeight.w700 : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'youtu.be/$videoId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.graphic_eq_rounded,
                              size: 16,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Now playing',
                              style: tt.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.videoId, required this.selected});

  final String videoId;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: SizedBox(
        width: PlaylistTile._thumbWidth,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                YoutubePlayerController.getThumbnail(
                  videoId: videoId,
                  quality: .medium,
                ),
                fit: .cover,
                // Decode at the displayed size, not the full resolution.
                cacheWidth:
                    (PlaylistTile._thumbWidth *
                            MediaQuery.devicePixelRatioOf(context))
                        .round(),
                webHtmlElementStrategy: .fallback,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: cs.surfaceContainerHighest,
                  child: Icon(
                    Icons.ondemand_video_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              if (selected)
                ColoredBox(
                  color: Colors.black45,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: cs.primary,
                    size: 36,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
