// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/src/utils/live_duration_calculator.dart';

import '../../youtube_player_flutter.dart';
import '../utils/youtube_player_controller.dart';
import 'duration_widgets.dart';
import 'full_screen_button.dart';

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
  int _selectedTimeMs = 0;

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
    super.dispose();
  }

  void listener() {
    if (mounted) {
      setState(() {
        final liveDurationTimes = LiveDurationCalculator.getDuration(
            controller: _controller, selectedTimeMs: _selectedTimeMs);

        final totalTimeMs = liveDurationTimes.totalVideoTimeMs;
        final durationMs = liveDurationTimes.videoDurationMs;

        final minimumTimeMs = totalTimeMs - durationMs;
        final newPositionMs =
            liveDurationTimes.selectedPositionMs - minimumTimeMs;

        final double newPosition = totalTimeMs == 0 || newPositionMs < 0
            ? 0
            : newPositionMs / durationMs;

        //Init check for setting the initial time of the live view to
        //the max time (i.e. setting it to "Live")
        //_controller is not ready in the didChangeState or initState overrides,
        //so need to do here
        if (!_init && totalTimeMs > 0) {
          _selectedTimeMs = totalTimeMs;
          _init = true;
        }
        _currentSliderPosition = newPosition > 1 ? 1 : newPosition;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //Hide the "Live" button if the stream is set to max value on slider
    final isRealtime = _currentSliderPosition == 1;

    //To keep consistent spacing, set live button to transparent / disabled
    //if the time bar is at maximum value
    final liveButton = InkWell(
      onTap: isRealtime
          ? null
          : () {
              _controller.seekTo(Duration(
                  milliseconds: _controller.metadata.totalVideoLengthMs));
              _selectedTimeMs = _controller.value.position.inMilliseconds;
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
            selectedTimeMs: _selectedTimeMs,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Slider(
                value: _currentSliderPosition,
                onChanged: (value) {
                  final durationMs = _controller.metadata.totalVideoLengthMs;
                  final vidLengthMs =
                      _controller.metadata.duration.inMilliseconds;
                  final minMs = durationMs - vidLengthMs;

                  final selectedPosition =
                      (vidLengthMs * value).round() + minMs;
                  final newPosition = selectedPosition > durationMs
                      ? durationMs
                      : selectedPosition;

                  _controller.seekTo(
                    Duration(
                      milliseconds: newPosition,
                    ),
                  );
                  _selectedTimeMs = _controller.value.position.inMilliseconds;
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
