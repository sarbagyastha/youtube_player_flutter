// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:youtube_player_iframe/src/iframe_api/src/functions/playback_controls.dart';
import 'package:youtube_player_iframe/src/iframe_api/src/functions/playback_status.dart';
import 'package:youtube_player_iframe/src/iframe_api/src/functions/player_settings.dart';
import 'package:youtube_player_iframe/src/iframe_api/src/functions/video_information.dart';

import 'src/functions/queueing_functions.dart';

export 'src/functions/queueing_functions.dart' show ListType;

/// Interface for the YouTube IFrame Player API, implemented by [YoutubePlayerController].
abstract class YoutubePlayerIFrameAPI
    implements
        QueueingFunctions,
        VideoInformation,
        PlayerSettings,
        PlaybackControls,
        PlaybackStatus {}
