// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'bottom_bar.dart';
import 'buffering_indicator.dart';
import 'playback_controls.dart';
import 'title_bar.dart';

/// The default controls overlay.
///
/// Composed of a top [TitleBar], centered [PlaybackControls], and a
/// bottom [BottomBar]. A [BufferingIndicator] floats in the centre.
class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    // Stack fills the full screen (StackFit.expand). Safe-area padding for the
    // home indicator in landscape fullscreen is handled inside BottomBar so the
    // gradient can extend all the way to the screen edge.
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            TitleBar(controller: controller),
            const Spacer(),
            BottomBar(controller: controller),
          ],
        ),
        Center(child: PlaybackControls(controller: controller)),
        Center(child: BufferingIndicator(controller: controller)),
      ],
    );
  }
}
