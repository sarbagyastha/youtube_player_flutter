import 'package:flutter/material.dart';
import 'package:youtube_player_iframe_example/widgets/controls/info_tab.dart';
import 'package:youtube_player_iframe_example/widgets/controls/playback_tab.dart';
import 'package:youtube_player_iframe_example/widgets/controls/source_tab.dart';

const _kTabViewHeight = 380.0;

class ControlsPanel extends StatelessWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Playback'),
              Tab(text: 'Info'),
              Tab(text: 'Source'),
            ],
          ),
          SizedBox(
            height: _kTabViewHeight,
            child: TabBarView(
              children: [
                PlaybackTab(),
                InfoTab(),
                SourceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
