import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const List<String> _videoIds = [
  'dHuYBB05bYU',
  'RpoFTgWRfJ4',
  '82u-4xcsyJU',
];

///
class VideoListPage extends StatelessWidget {
  ///
  const VideoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video List Demo'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _videoIds.length,
        itemBuilder: (context, index) {
          final videoId = _videoIds[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: YoutubePlayerIFrame(
                key: ValueKey(videoId),
                aspectRatio: 16 / 9,
                enableFullScreenOnVerticalDrag: false,
                controller:
                    YoutubePlayerController.fromVideoId(videoId: videoId),
              ),
            ),
          );
        },
        separatorBuilder: (context, _) => const SizedBox(height: 16),
      ),
    );
  }
}
