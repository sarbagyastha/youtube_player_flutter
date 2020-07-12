// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
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
  final YoutubePlayerController controller;

  /// Aspect ratio for the player.
  final double aspectRatio;

  /// A widget to play or stream Youtube Videos.
  const YoutubePlayerIFrame({
    Key key,
    this.controller,
    this.aspectRatio = 16 / 9,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: RawYoutubePlayer(controller ?? context.ytController),
    );
  }
}
