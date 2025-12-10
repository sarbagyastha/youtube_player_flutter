// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../utils/duration_formatter.dart';
import '../utils/youtube_player_controller.dart';

/// A widget which displays the current position of the video.
class CurrentPosition extends StatefulWidget {
  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;
  final int? selectedTimeMs;

  /// Creates [CurrentPosition] widget.
  const CurrentPosition({
    super.key,
    this.controller,
    this.selectedTimeMs,
  });

  @override
  State<CurrentPosition> createState() => _CurrentPositionState();
}

class _CurrentPositionState extends State<CurrentPosition> {
  late YoutubePlayerController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = YoutubePlayerController.of(context);
    if (controller == null) {
      assert(
        widget.controller != null,
        '\n\nNo controller could be found in the provided context.\n\n'
        'Try passing the controller explicitly.',
      );
      _controller = widget.controller!;
    } else {
      _controller = controller;
    }
    _controller.removeListener(listener);
    _controller.addListener(listener);
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    super.dispose();
  }

  void listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final flags = _controller.flags;
    final decoration = flags.timeDecoration;

    final timeDisplay = durationFormatterFromController(
      _controller,
      countDown: false,
      selectedTimeMs: widget.selectedTimeMs,
    );
    final textWidget = Text(
      ' $timeDisplay ',
      style: TextStyle(
        color: flags.timeTextColor,
        fontSize: 12.0,
      ),
    );
    if (decoration == null) {
      return textWidget;
    }
    return DecoratedBox(decoration: decoration, child: textWidget);
  }
}

/// A widget which displays the remaining duration of the video.
class RemainingDuration extends StatefulWidget {
  /// Creates [RemainingDuration] widget.
  const RemainingDuration({
    super.key,
    this.controller,
    this.selectedTimeMs,
  });

  final int? selectedTimeMs;

  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  @override
  State<RemainingDuration> createState() => _RemainingDurationState();
}

class _RemainingDurationState extends State<RemainingDuration> {
  late YoutubePlayerController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = YoutubePlayerController.of(context);
    if (controller == null) {
      assert(
        widget.controller != null,
        '\n\nNo controller could be found in the provided context.\n\n'
        'Try passing the controller explicitly.',
      );
      _controller = widget.controller!;
    } else {
      _controller = controller;
    }
    _controller.removeListener(listener);
    _controller.addListener(listener);
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    super.dispose();
  }

  void listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final flags = _controller.flags;
    final decoration = flags.timeDecoration;

    final timeDisplay = durationFormatterFromController(
      _controller,
      countDown: true,
      selectedTimeMs: widget.selectedTimeMs,
    );
    final textWidget = Text(
      ' $timeDisplay ',
      style: TextStyle(
        color: flags.timeTextColor,
        fontSize: 12.0,
      ),
    );
    if (decoration == null) {
      return textWidget;
    }
    return DecoratedBox(decoration: decoration, child: textWidget);
  }
}
