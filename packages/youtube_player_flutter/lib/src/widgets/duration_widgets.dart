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

  /// Creates [CurrentPosition] widget.
  const CurrentPosition({super.key, this.controller});

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
    return Stack(
      children: [
        Text(
          "${_controller.value.position.inHours != 0 ? '66:' : ''}66:66",
          key: const Key('hidden-current-position-text'),
          style: const TextStyle(
            color: Colors.transparent,
            fontSize: 12.0,
          ),
        ),
        Text(
          durationFormatter(
            _controller.value.position.inMilliseconds,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}

/// A widget which displays the remaining duration of the video.
class RemainingDuration extends StatefulWidget {
  /// Creates [RemainingDuration] widget.
  const RemainingDuration({super.key, this.controller});

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
    return Stack(
      children: [
        Text(
          "- ${_controller.value.position.inHours != 0 ? '66:' : ''}66:66",
          key: const Key('hidden-remaining-duration-text'),
          style: const TextStyle(
            color: Colors.transparent,
            fontSize: 12.0,
          ),
        ),
        Text(
          "- ${durationFormatter(
            (_controller.metadata.duration.inMilliseconds) -
                (_controller.value.position.inMilliseconds),
          )}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}
