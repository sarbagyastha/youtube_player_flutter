// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../data.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/custom_builder_demo.dart';
import '../widgets/player_page_widgets.dart';
import '../widgets/thumbnail_card.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.seedColor,
    required this.onColorChanged,
  });

  final Color seedColor;
  final ValueChanged<Color> onColorChanged;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final YoutubePlayerController _controller;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Player Flutter'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Theme color',
              icon: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              onPressed: () => ColorPickerSheet.show(
                context,
                selected: widget.seedColor,
                onSelected: widget.onColorChanged,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          YoutubePlayer(controller: _controller),
          NowPlaying(controller: _controller),
          const SizedBox(height: 20),
          SectionHeader(
            icon: Icons.queue_music_rounded,
            title: 'Playlist',
            trailing: Text(
              '${videoIds.length} videos',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: CarouselView(
              itemExtent: 190,
              shrinkExtent: 110,
              itemSnapping: false,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onTap: _loadVideo,
              children: [
                for (var i = 0; i < videoIds.length; i++)
                  ThumbnailCard(
                    videoId: videoIds[i],
                    selected: i == _currentIndex,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Divider(height: 0, indent: 16, endIndent: 16),
          const SizedBox(height: 20),
          const SectionHeader(
            icon: Icons.tune_rounded,
            title: 'Custom Controls',
          ),
          const SizedBox(height: 10),
          const CustomBuilderDemo(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
