// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Shows a [CircularProgressIndicator] only while the player is buffering.
class BufferingIndicator extends StatelessWidget {
  const BufferingIndicator({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.playerState != n.playerState,
      builder: (context, value) {
        final isBuffering = value.playerState == PlayerState.buffering;
        return IgnorePointer(
          ignoring: !isBuffering,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isBuffering ? 1.0 : 0.0,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
