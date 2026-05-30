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
    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        final screenSize = MediaQuery.sizeOf(context);
        final isLandscapeFullscreen =
            value.fullScreenOption.enabled &&
            screenSize.width > screenSize.height;
        return SafeArea(
          top: false,
          bottom: isLandscapeFullscreen,
          left: false,
          right: false,
          child: Stack(
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
          ),
        );
      },
    );
  }
}
