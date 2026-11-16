import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/videos.dart';
import '../widgets/video_thumbnail.dart';

/// Every [ThumbnailQuality] in each [ThumbnailFormat].
class const ThumbnailsPage({super.key}) extends StatefulWidget {
  @override
  State<ThumbnailsPage> createState() => _ThumbnailsPageState();
}

class _ThumbnailsPageState extends State<ThumbnailsPage> {
  var _index = 0;
  var _format = ThumbnailFormat.jpeg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videoId = videoIds[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Thumbnails')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const .fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  VideoStrip(
                    videoIds: videoIds,
                    selectedIndex: _index,
                    height: 72,
                    onSelected: (i) => setState(() => _index = i),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<ThumbnailFormat>(
                    segments: const [
                      ButtonSegment(value: .jpeg, label: Text('JPEG')),
                      ButtonSegment(value: .webp, label: Text('WebP')),
                    ],
                    selected: {_format},
                    onSelectionChanged: (s) =>
                        setState(() => _format = s.single),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const .fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
              ),
              itemCount: ThumbnailQuality.values.length,
              itemBuilder: (context, i) {
                final quality = ThumbnailQuality.values[i];
                final url = YoutubePlayerController.getThumbnail(
                  videoId: videoId,
                  quality: quality,
                  format: _format,
                );
                return Card(
                  clipBehavior: .antiAlias,
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      VideoThumbnail(
                        videoId,
                        quality: quality,
                        format: _format,
                        radius: 0,
                      ),
                      ListTile(
                        contentPadding: const .symmetric(horizontal: 16),
                        title: Text(quality.name),
                        subtitle: Text(
                          '${quality.value}.${_format == .jpeg ? 'jpg' : 'webp'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: 'Copy URL',
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied $url')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
