// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Play YouTube videos inline through the official IFrame Player API.
library;

export 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart'
    show
        FullscreenOrientation,
        PlayerState,
        SphericalProperties,
        VideoData,
        YoutubeError,
        YoutubeLoadError;

export 'src/controller.dart' show LinkTapHandler, YoutubePlayerController;
export 'src/iframe_api.dart';
export 'src/params.dart';
export 'src/value.dart';
export 'src/widgets/value_builder.dart';
export 'src/widgets/youtube_player.dart';
