// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'src/controller.dart';
import 'src/helpers/youtube_value_provider.dart';

import 'src/players/youtube_player_mobile.dart'
    if (dart.library.html) 'src/players/youtube_player_web.dart';

export 'src/controller.dart';
export 'src/enums/playback_rate.dart';
export 'src/enums/player_state.dart';
export 'src/enums/playlist_type.dart';
export 'src/enums/thumbnail_quality.dart';
export 'src/enums/youtube_error.dart';
export 'src/helpers/youtube_value_builder.dart';
export 'src/helpers/youtube_value_provider.dart';
export 'src/meta_data.dart';
export 'src/player_params.dart';

/// A widget to play or stream Youtube Videos.
class YoutubePlayerIFrame extends StatelessWidget {
  /// The [controller] for this player.
  final YoutubePlayerController? controller;

  /// Aspect ratio for the player.
  final double aspectRatio;

  /// Which gestures should be consumed by the youtube player.
  ///
  /// It is possible for other gesture recognizers to be competing with the player on pointer
  /// events, e.g if the player is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The player will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// By default vertical and horizontal gestures are absorbed by the player.
  /// Passing an empty set will ignore the defaults.
  ///
  /// This is ignored on web.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// A widget to play or stream Youtube Videos.
  const YoutubePlayerIFrame({
    Key? key,
    this.controller,
    this.aspectRatio = 16 / 9,
    this.gestureRecognizers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: RawYoutubePlayer(
        controller: controller ?? context.ytController,
        gestureRecognizers: gestureRecognizers,
      ),
    );
  }
}
