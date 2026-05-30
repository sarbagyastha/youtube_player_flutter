// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// Re-export the full youtube_player_iframe public API.
// YoutubePlayer is hidden here; this package's widget uses the same name.
export 'package:youtube_player_iframe/youtube_player_iframe.dart'
    hide YoutubePlayer;

// This package's additions.
export 'src/theme/youtube_player_theme.dart';
export 'src/widgets/controls/fullscreen_button.dart';
export 'src/widgets/typedefs.dart';
export 'src/widgets/youtube_player.dart';

