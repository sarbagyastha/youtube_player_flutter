// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../theme/youtube_player_theme.dart';
import 'speed_control.dart';

/// Top action bar with speed control aligned to the right.
class TitleBar extends StatelessWidget {
  const TitleBar({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        final double left;
        final double right;
        if (value.fullScreenOption.enabled) {
          final p = MediaQuery.paddingOf(context);
          left = math.max(4.0, p.left);
          right = math.max(4.0, p.right);
        } else {
          left = 4.0;
          right = 4.0;
        }

        return Container(
          decoration: BoxDecoration(gradient: theme.topGradient),
          padding: EdgeInsets.fromLTRB(left, 4, right, 4),
          child: Row(
            children: [
              const Spacer(),
              SpeedControl(controller: controller, useIcon: true),
            ],
          ),
        );
      },
    );
  }
}
