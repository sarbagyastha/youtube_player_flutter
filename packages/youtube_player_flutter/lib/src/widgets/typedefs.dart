// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

/// Signature for a builder that provides a fully custom controls UI.
///
/// - [context]: the current build context.
/// - [player]: the video surface, sized by `YoutubePlayer.aspectRatio`
///   inline and filling the screen in fullscreen.
/// - [controller]: the underlying [YoutubePlayerController] for full control.
///
/// ### Example
/// ```dart
/// YoutubePlayer(
///   controller: controller,
///   builder: (context, player, ctrl) => Stack(
///     children: [
///       player,
///       Positioned(bottom: 0, left: 0, right: 0, child: MyControls(controller: ctrl)),
///     ],
///   ),
/// )
/// ```
typedef YoutubePlayerBuilder = Widget Function(
  BuildContext context,
  Widget player,
  YoutubePlayerController controller,
);
