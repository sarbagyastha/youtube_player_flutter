import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../data.dart';
import '../widgets/custom_builder_demo.dart';
import '../widgets/thumbnail_card.dart';
import 'theme_demo_page.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late YoutubePlayerController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoIds[_currentIndex],
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: false,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _loadVideo(int index) {
    setState(() => _currentIndex = index);
    _controller.loadVideoById(videoId: videoIds[index]);
  }

  void _showThemeDemo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ThemeDemoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Player Flutter'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showThemeDemo,
            tooltip: 'Theme demo',
          ),
        ],
      ),
      body: ListView(
        children: [
          YoutubePlayer(controller: _controller),
          const SizedBox(height: 32),
          SizedBox(
            height: 90,
            child: CarouselView(
              itemExtent: 180,
              shrinkExtent: 100,
              itemSnapping: false,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onTap: _loadVideo,
              children: [
                for (var i = 0; i < videoIds.length; i++)
                  ThumbnailCard(videoId: videoIds[i], selected: i == _currentIndex),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(height: 0),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Custom Controls',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const CustomBuilderDemo(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
