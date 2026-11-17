// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../../fullscreen/fullscreen.dart';
import '../../theme/youtube_player_theme.dart';
import '../../utils/duration_formatter.dart';
import 'fullscreen_button.dart';
import 'progress_bar.dart';

/// Bottom gradient bar: time pill + fullscreen button, then a thin seek slider.
class const BottomBar({
  super.key,
  required final YoutubePlayerController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    return ValueListenableBuilder<bool>(
      valueListenable: YoutubeFullScreen.of(context, listen: false),
      builder: (context, isFullScreen, _) {
        // In fullscreen, use safe-area insets as a floor for horizontal padding
        // (max rather than add) so controls clear the notch without doubling
        // the existing spacing. Bottom inset is added for the home indicator.
        final EdgeInsets insets;
        if (isFullScreen) {
          final p = MediaQuery.paddingOf(context);
          insets = EdgeInsets.fromLTRB(
            math.max(12.0, p.left),
            0,
            math.max(4.0, p.right),
            p.bottom,
          );
        } else {
          insets = EdgeInsets.only(left: 16);
        }

        return Container(
          decoration: BoxDecoration(gradient: theme.bottomGradient),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(insets.left, 4, insets.right, 0),
                child: Row(
                  children: [
                    _TimePill(controller: controller, theme: theme),
                    const Spacer(),
                    const FullscreenButton(),
                  ],
                ),
              ),
              ProgressBar(
                controller: controller,
                leftPadding: insets.left,
                rightPadding: insets.right,
              ),
              SizedBox(height: insets.bottom),
            ],
          ),
        );
      },
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.controller, required this.theme});

  final YoutubePlayerController controller;
  final YoutubePlayerThemeResolver theme;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<YoutubeVideoState>(
      stream: controller.videoStateStream,
      builder: (context, snapshot) {
        final position = snapshot.data?.position ?? Duration.zero;
        final duration = controller.metadata.duration;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: const BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Text(
            '${position.toHhMmSs()} / ${duration.toHhMmSs()}',
            style: theme.timerStyle,
          ),
        );
      },
    );
  }
}
