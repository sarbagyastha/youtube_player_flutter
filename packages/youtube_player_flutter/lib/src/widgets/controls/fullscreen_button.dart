// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:material_ui/material_ui.dart';

import '../../controller/overlay_controller_scope.dart';
import '../../fullscreen/fullscreen.dart';
import '../../theme/youtube_player_theme.dart';

/// Toggles fullscreen of the enclosing `YoutubePlayer`.
///
/// Must be placed below a `YoutubePlayer` from this package, e.g. in its
/// `builder`.
class const FullscreenButton({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);
    final fullScreen = YoutubeFullScreen.of(context);

    return IconButton(
      icon: Icon(
        fullScreen.isFullScreen
            ? Icons.fullscreen_exit_rounded
            : Icons.fullscreen_rounded,
        color: theme.controlsColor,
      ),
      onPressed: () {
        fullScreen.toggle();
        OverlayControllerScope.maybeOf(context)?.resetTimer();
      },
    );
  }
}
