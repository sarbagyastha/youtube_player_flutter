// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';
import 'duration_widgets.dart';
import 'full_screen_button.dart';

/// A widget to display bottom controls bar on Live Video Mode.
class LiveBottomBar extends StatefulWidget {
  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController controller;

  /// Defines color for UI.
  final Color liveUIColor;

  /// Creates [LiveBottomBar] widget.
  LiveBottomBar({
    this.controller,
    @required this.liveUIColor,
  });

  @override
  _LiveBottomBarState createState() => _LiveBottomBarState();
}

class _LiveBottomBarState extends State<LiveBottomBar> {
  double _currentSliderPosition = 0.0;

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
    _controller.addListener(listener);
  }

  @override
  void dispose() {
    _controller?.removeListener(listener);
    super.dispose();
  }

  void listener() {
    if (mounted) {
      setState(() {
        _currentSliderPosition =
            _controller.metadata.duration.inMilliseconds == 0
                ? 0
                : _controller.value.position.inMilliseconds /
                    _controller.metadata.duration.inMilliseconds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _controller.value.isControlsVisible,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 14.0,
          ),
          CurrentPosition(),
          Expanded(
            child: Padding(
              child: Slider(
                value: _currentSliderPosition,
                onChanged: (value) {
                  _controller.seekTo(
                    Duration(
                      milliseconds:
                          (_controller.metadata.duration.inMilliseconds * value)
                              .round(),
                    ),
                  );
                },
                activeColor: widget.liveUIColor,
                inactiveColor: Colors.transparent,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
            ),
          ),
          InkWell(
            onTap: () => _controller.seekTo(_controller.metadata.duration),
            child: Material(
              color: widget.liveUIColor,
              child: const Text(
                ' LIVE ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          FullScreenButton(
            controller: _controller,
          ),
        ],
      ),
    );
  }
}
