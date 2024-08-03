import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const List<String> _videoIds = [
  'dHuYBB05bYU',
  'RpoFTgWRfJ4',
  '82u-4xcsyJU',
];

///
class VideoListPage extends StatefulWidget {
  ///
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  late final List<YoutubePlayerController> _controllers;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      _videoIds.length,
      (index) {
        final controller = YoutubePlayerController.fromVideoId(
          videoId: _videoIds[index],
          autoPlay: false,
          params: const YoutubePlayerParams(showFullscreenButton: true),
        );
        controller.setFullScreenListener(
          (_) async {
            final videoData = await controller.videoData;
            final startSeconds = await controller.currentTime;

            if (context.mounted) {
              final currentTime = await FullscreenYoutubePlayer.launch(
                context,
                videoId: videoData.videoId,
                startSeconds: startSeconds,
              );

              if (currentTime != null) {
                controller.seekTo(seconds: currentTime);
              }
            }
          },
        );

        return controller;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video List Demo'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width > 500 ? 2 : 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 16 / 9,
        ),
        itemCount: _controllers.length,
        itemBuilder: (context, index) {
          final controller = _controllers[index];

          return YoutubePlayer(
            key: ObjectKey(controller),
            aspectRatio: 16 / 9,
            enableFullScreenOnVerticalDrag: false,
            controller: controller,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.close();
    }

    super.dispose();
  }
}
