// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../theme/youtube_player_theme.dart';
import '../../utils/duration_formatter.dart';
import 'fullscreen_button.dart';
import 'progress_bar.dart';

/// Bottom gradient bar: time pill + fullscreen button, then a thin seek slider.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        // In fullscreen, use safe-area insets as a floor for horizontal padding
        // (max rather than add) so controls clear the notch without doubling
        // the existing spacing. Bottom inset is added for the home indicator.
        final EdgeInsets insets;
        if (value.fullScreenOption.enabled) {
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
                    FullscreenButton(controller: controller),
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
