// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:youtube_player_flutter/src/utils/live_duration_calculator.dart';
import 'package:youtube_player_flutter/src/utils/youtube_player_controller.dart';

/// Formats duration in milliseconds to xx:xx:xx format.
String durationFormatter(int milliseconds, bool isLive) {
  var seconds = milliseconds ~/ 1000;
  final hours = seconds ~/ 3600;
  seconds = seconds % 3600;
  var minutes = seconds ~/ 60;
  seconds = seconds % 60;
  final hoursString = hours >= 10
      ? '$hours'
      : hours == 0
          ? '00'
          : '0$hours';
  final minutesString = minutes >= 10
      ? '$minutes'
      : minutes == 0
          ? '00'
          : '0$minutes';
  final secondsString = seconds >= 10
      ? '$seconds'
      : seconds == 0
          ? '00'
          : '0$seconds';
  return '${hoursString == '00' ? '' : '$hoursString:'}$minutesString:$secondsString';
}

/// Use controller values to determine the position of livestreams using current values
String durationFormatterFromController(YoutubePlayerController controller,
    {required bool countDown, int? selectedTimeMs}) {
  final bool isLive = controller.metadata.isLive;

  if (!isLive) {
    final controllerPosition = controller.value.position.inMilliseconds;
    final int position = controllerPosition;
    final int videoLengthMs = controller.metadata.totalVideoLengthMs;
    final offset = countDown ? videoLengthMs - position : position;

    return durationFormatter(offset, isLive);
  }
  final liveStreamTimes = LiveDurationCalculator.getDuration(
      controller: controller, selectedTimeMs: selectedTimeMs ?? 0);

  final offset =
      liveStreamTimes.totalVideoTimeMs - liveStreamTimes.selectedPositionMs;

  if (offset <= 0) {
    return 'Live';
  }

  final formattedTime = durationFormatter(offset, isLive);
  return '-$formattedTime';
}
