import 'package:flutter/material.dart';
import 'package:youtube_player_iframe_example/widgets/controls/info_tab.dart';
import 'package:youtube_player_iframe_example/widgets/controls/playback_tab.dart';
import 'package:youtube_player_iframe_example/widgets/controls/source_tab.dart';

const _kTabViewHeight = 320.0;

class ControlsPanel extends StatelessWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const InfoTab(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const TabBar(
                tabs: [
                  Tab(text: 'Playback'),
                  Tab(text: 'Source'),
                ],
              ),
            ),
          ),
          SizedBox(
            height: _kTabViewHeight,
            child: const TabBarView(
              children: [
                PlaybackTab(),
                SourceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
