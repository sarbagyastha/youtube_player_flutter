import 'package:flutter/material.dart';
import 'package:youtube_player_iframe_example/widgets/controls/info_tab.dart';
import 'package:youtube_player_iframe_example/widgets/controls/playback_tab.dart';
import 'package:youtube_player_iframe_example/widgets/controls/source_tab.dart';

const _kTabViewHeight = 270.0;

class ControlsPanel extends StatelessWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const InfoTab(),
          const Divider(height: 1),
          const TabBar(
            tabs: [
              Tab(text: 'Playback'),
              Tab(text: 'Source'),
            ],
          ),
          SizedBox(
            height: _kTabViewHeight,
            child: const TabBarView(children: [PlaybackTab(), SourceTab()]),
          ),
        ],
      ),
    );
  }
}
