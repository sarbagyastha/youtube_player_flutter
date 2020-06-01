// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../utils/duration_formatter.dart';
import '../utils/youtube_player_controller.dart';

/// A widget which displays the current position of the video.
class CurrentPosition extends StatefulWidget {
  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController controller;

  /// Creates [CurrentPosition] widget.
  CurrentPosition({this.controller});

  @override
  _CurrentPositionState createState() => _CurrentPositionState();
}

class _CurrentPositionState extends State<CurrentPosition> {
  YoutubePlayerController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = YoutubePlayerController.of(context);
    if (_controller == null) {
      assert(
        widget.controller != null,
        '\n\nNo controller could be found in the provided context.\n\n'
        'Try passing the controller explicitly.',
      );
      _controller = widget.controller;
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
    return Text(
      durationFormatter(
        _controller.value.position?.inMilliseconds ?? 0,
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
      ),
    );
  }
}

/// A widget which displays the remaining duration of the video.
class RemainingDuration extends StatefulWidget {
  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController controller;

  /// Creates [RemainingDuration] widget.
  RemainingDuration({this.controller});

  @override
  _RemainingDurationState createState() => _RemainingDurationState();
}

class _RemainingDurationState extends State<RemainingDuration> {
  YoutubePlayerController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = YoutubePlayerController.of(context);
    if (_controller == null) {
      assert(
        widget.controller != null,
        '\n\nNo controller could be found in the provided context.\n\n'
        'Try passing the controller explicitly.',
      );
      _controller = widget.controller;
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
    return Text(
      "- ${durationFormatter(
        (_controller.metadata.duration?.inMilliseconds ?? 0) -
            (_controller.value.position?.inMilliseconds ?? 0),
      )}",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
      ),
    );
  }
}
