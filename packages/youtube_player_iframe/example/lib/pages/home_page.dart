// Copyright 2024 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_player_iframe_example/router.dart';
import 'package:youtube_player_iframe_example/widgets/controls/controls_panel.dart';
import 'package:youtube_player_iframe_example/widgets/player/player_view.dart';

const List<String> _videoIds = [
  'tcodrIK2P_I',
  'H5v3kku4y6Q',
  'nPt8bK2gbaU',
  'K18cpp_-gP8',
  'iLnmTe5Q2Qw',
  '_WoCV4c6XOE',
  'KmzdUe0RSJo',
  '6jZDSSZZxjQ',
  'p2lYr3vM_1w',
  '7QUtEmBT_-w',
  '34_PXCzGw1M',
];

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.videoId});

  final String? videoId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late YoutubePlayerController _controller;
  late final GlobalObjectKey _playerKey;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
        
      ),
    );

    _controller.setFullScreenListener((isFullScreen) {
      log('${isFullScreen ? 'Entered' : 'Exited'} Fullscreen.');
    });

    if (widget.videoId != null) {
      _controller.loadVideoById(videoId: widget.videoId!);
    } else {
      _controller.loadPlaylist(
        list: _videoIds,
        listType: ListType.playlist,
        startSeconds: 136,
      );
    }

    _playerKey = GlobalObjectKey(_controller);
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerView(key: _playerKey, controller: _controller);

    return YoutubePlayerControllerProvider(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('YT Player IFrame'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _VideoPlaylistButton(),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 750) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: player),
                  const Expanded(
                    flex: 2,
                    child: SingleChildScrollView(child: ControlsPanel()),
                  ),
                ],
              );
            }

            return ListView(children: [player, const ControlsPanel()]);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

class _VideoPlaylistButton extends StatelessWidget {
  const _VideoPlaylistButton();

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;

    return IconButton.filledTonal(
      onPressed: () async {
        controller.pauseVideo();
        router.go('/playlist');
      },
      icon: const Icon(Icons.playlist_play_rounded),
      tooltip: 'Playlist',
    );
  }
}
