// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../data.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/player_page_widgets.dart';
import '../widgets/playlist_tile.dart';
import 'custom_controls_page.dart';

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

  /// Selected playlist item. A notifier, so selecting a video rebuilds only
  /// the carousel, not the page or the player.
  final _currentIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoIds[_currentIndex.value],
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
    _currentIndex.dispose();
    _controller.close();
    super.dispose();
  }

  void _loadVideo(int index) {
    _currentIndex.value = index;
    _controller.loadVideoById(videoId: videoIds[index]);
  }

  void _openCustomControls() {
    // This page stays alive under the new one; don't play behind it.
    _controller.pauseVideo();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CustomControlsPage()));
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
          IconButton(
            tooltip: 'Custom controls',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openCustomControls,
          ),
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
      // The player is pinned above the scrolling content: a native view that
      // never moves with the scroll offset costs nothing per scroll frame.
      body: Column(
        children: [
          YoutubePlayer(controller: _controller),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: NowPlaying(controller: _controller)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: SectionHeader(
                    icon: Icons.queue_music_rounded,
                    title: 'Up next',
                    trailing: Text(
                      '${videoIds.length} videos',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                // Built lazily; selecting a video rebuilds only the list.
                ValueListenableBuilder<int>(
                  valueListenable: _currentIndex,
                  builder: (context, currentIndex, _) => SliverList.builder(
                    itemCount: videoIds.length,
                    itemBuilder: (context, i) => PlaylistTile(
                      index: i,
                      videoId: videoIds[i],
                      selected: i == currentIndex,
                      onTap: () => _loadVideo(i),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 16 + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
