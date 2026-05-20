// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/src/utils/live_duration_calculator.dart';

import '../../youtube_player_flutter.dart';

/// This widget is used to display display bottom controls bar on Live Video Mode.
class LiveBottomBar extends StatefulWidget {
  /// Creates [LiveBottomBar] widget.
  const LiveBottomBar({
    super.key,
    this.controller,
    required this.liveUIColor,
    required this.showLiveFullscreenButton,
  });

  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  /// Defines color for UI.
  final Color liveUIColor;

  /// Defines whether to show or hide the fullscreen button
  final bool showLiveFullscreenButton;

  @override
  State<LiveBottomBar> createState() => _LiveBottomBarState();
}

class _LiveBottomBarState extends State<LiveBottomBar> {
  double _currentSliderPosition = 0.0;
  late YoutubePlayerController _controller;

  bool _init = false;
  final _selectedTimeController = ValueNotifier<int>(0);

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
    _controller.addListener(listener);
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    _selectedTimeController.dispose();
    super.dispose();
  }

  void listener() {
    if (mounted) {
      // Init check for setting the initial time of the live view to
      // the max time (i.e. setting it to "Live")
      // _controller is not ready in the didChangeState or initState overrides,
      // so need to do here
      if (!_init && _controller.metadata.totalVideoLengthMs > 0) {
        _selectedTimeController.value = _controller.metadata.totalVideoLengthMs;
        _init = true;
      }

      final liveDurationTimes = LiveDurationCalculator.getDuration(
          controller: _controller,
          selectedTimeMs: _selectedTimeController.value);

      // final startingVideoLengthMs = _controller.metadata.startingVideoLengthMs;
      final totalTimeMs = liveDurationTimes.totalVideoTimeMs;

      final durationMs = liveDurationTimes.videoDurationMs;


      final minimumTimeMs = totalTimeMs - durationMs;
      final newPositionMs =
          liveDurationTimes.selectedPositionMs - minimumTimeMs;

      final double newPosition = totalTimeMs == 0 || newPositionMs < 0
          ? 0
          : newPositionMs / durationMs;
      setState(() {
        _currentSliderPosition = newPosition > 1 ? 1 : newPosition;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide the "Live" button if the stream is set to max value on slider
    final isRealtime = _currentSliderPosition == 1;

    // To keep consistent spacing, set live button to transparent / disabled
    // if the time bar is at maximum value
    final liveButton = InkWell(
      onTap: isRealtime
          ? null
          : () {
        // Offset the time total by 20 seconds because the totalVideoLength can be behind
        // the new value sent by the callback in raw_youtube_play.dart due to the tickrate
        // of the callback
        final int videoLengthMs = _controller.metadata.totalVideoLengthMs +
            20000;

        _selectedTimeController.value = videoLengthMs;
        _controller.seekTo(Duration(milliseconds: videoLengthMs));
      },
      child: Material(
        color: isRealtime ? Colors.transparent : widget.liveUIColor,
        child: Text(
          ' LIVE ',
          style: TextStyle(
            color: isRealtime ? Colors.transparent : Colors.white,
            fontSize: 12.0,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
    return Visibility(
      visible: _controller.value.isControlsVisible,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 14.0,
          ),
          CurrentPosition(
            selectedTimeMs: _selectedTimeController.value,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Slider(
                value: _currentSliderPosition,
                onChanged: (value) {
                  final livestreamTimes = LiveDurationCalculator.getDuration(
                    controller: _controller,
                    selectedTimeMs: _selectedTimeController.value,
                  );
                  final durationMs = livestreamTimes.videoDurationMs;
                  final vidLengthMs = livestreamTimes.totalVideoTimeMs;
                  final minMs = vidLengthMs - durationMs;

                  final selectedPosition =
                      (durationMs * value).round();
                  final newPosition = selectedPosition > maxDurationMs
                      ? maxDurationMs
                      : selectedPosition;

                  _selectedTimeController.value = newPosition + minMs;

                  _controller.seekTo(
                    Duration(
                      milliseconds: newPosition + minMs,
                    ),
                  );
                },
                activeColor: widget.liveUIColor,
                inactiveColor: Colors.transparent,
              ),
            ),
          ),
          liveButton,
          widget.showLiveFullscreenButton
              ? FullScreenButton(controller: _controller)
              : const SizedBox(width: 14.0),
        ],
      ),
    );
  }
}
