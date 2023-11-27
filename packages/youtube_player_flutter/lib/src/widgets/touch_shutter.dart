// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/duration_formatter.dart';
import '../utils/youtube_player_controller.dart';

/// A widget to display darkened translucent overlay, when video area is touched.
///
/// Also provides ability to seek video by dragging horizontally.
class TouchShutter extends StatefulWidget {
  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  /// If true, disables the drag to seek functionality.
  ///
  /// Default is false.
  final bool disableDragSeek;

  /// Sets the timeout until when the controls hide.
  final Duration timeOut;

  /// Creates [TouchShutter] widget.
  TouchShutter({
    this.controller,
    this.disableDragSeek = false,
    required this.timeOut,
  });

  @override
  _TouchShutterState createState() => _TouchShutterState();
}

class _TouchShutterState extends State<TouchShutter> {
  double dragStartPos = 0.0;
  double delta = 0.0;
  double scaleAmount = 0.0;
  int seekToPosition = 0;
  String seekDuration = "";
  String seekPosition = "";
  bool _dragging = false;
  Timer? _timer;
  Timer? _lockTimer;
  int doubleTapPadding = 50; // this disable the double tap effect in the middle
  bool doubleTapDetector = false;
  bool? tappedSide; // true means right side false means left side
  bool isLocked = false;
  bool showLockIcon = false;

  late double distanceFromCenter;
  late YoutubePlayerController _controller;
  late bool _doubleTapSkip;

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

    // initialize _doubleTapSkip
    if (_controller.flags.doubleTapSkipTime == 0) {
      _doubleTapSkip = false;
    } else {
      _doubleTapSkip = true;
    }
  }

  @override
  void initState() {
    distanceFromCenter = MediaQuery.of(context).size.width / 4;
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    if (isLocked) {
      showLockIcon = true;
      _lockTimer?.cancel();
      _lockTimer = Timer(widget.timeOut, () {
        showLockIcon = false;
      });
      return;
    }

    _controller.updateValue(
      _controller.value.copyWith(
        isControlsVisible: !_controller.value.isControlsVisible,
      ),
    );
    _timer?.cancel();
    _timer = Timer(widget.timeOut, () {
      if (!_controller.value.isDragging) {
        _controller.updateValue(
          _controller.value.copyWith(
            isControlsVisible: false,
          ),
        );
      }
    });
  }

  void onDoubleTapAction(TapDownDetails details) {
    if (!_doubleTapSkip || isLocked) return;

    if (details.globalPosition.dx >
        (MediaQuery.of(context).size.width / 2) + doubleTapPadding) {
      // touch on right side
      setState(() {
        doubleTapDetector = true;
        tappedSide = true;
      });
      _controller.seekTo(
        Duration(
            seconds: _controller.value.position.inSeconds +
                _controller.flags.doubleTapSkipTime),
      );
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          doubleTapDetector = false;
        });
      });
    } else if (details.globalPosition.dx <
        (MediaQuery.of(context).size.width / 2) - doubleTapPadding) {
      // touch on left side
      setState(() {
        doubleTapDetector = true;
        tappedSide = false;
      });
      _controller.seekTo(
        Duration(
            seconds: _controller.value.position.inSeconds -
                _controller.flags.doubleTapSkipTime),
      );
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          doubleTapDetector = false;
        });
      });
    }
  }

  Widget skipIcon(IconData icon, double dx) {
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Icon(
        icon,
        size: 100,
      ),
    );
  }

  void switchLock() {
    setState(() {
      isLocked = !isLocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      onDoubleTapDown: onDoubleTapAction,
      onHorizontalDragStart: (details) {
        if (_controller.flags.disableDragSeek || isLocked) return;
        setState(() {
          _dragging = true;
        });
        dragStartPos = details.globalPosition.dx;
      },
      onHorizontalDragUpdate: (details) {
        if (_controller.flags.disableDragSeek) return;
        _controller.updateValue(
          _controller.value.copyWith(
            isControlsVisible: false,
          ),
        );
        delta = details.globalPosition.dx - dragStartPos;
        seekToPosition =
            (_controller.value.position.inMilliseconds + delta * 1000).round();
        setState(() {
          seekDuration = (delta < 0 ? "- " : "+ ") +
              durationFormatter((delta < 0 ? -1 : 1) * (delta * 1000).round());
          if (seekToPosition < 0) seekToPosition = 0;
          seekPosition = durationFormatter(seekToPosition);
        });
      },
      onHorizontalDragEnd: (_) {
        if (isLocked) return;
        if (_controller.flags.disableDragSeek) return;
        _controller.seekTo(Duration(milliseconds: seekToPosition));
        setState(() {
          _dragging = false;
        });
      },
      onScaleUpdate: (details) {
        scaleAmount = details.scale;
      },
      onScaleEnd: (_) {
        if (isLocked) return;
        if (_controller.value.isFullScreen) {
          if (scaleAmount > 1) {
            _controller.fitWidth(MediaQuery.of(context).size);
          }
          if (scaleAmount < 1) {
            _controller.fitHeight(MediaQuery.of(context).size);
          }
        }
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: _controller.value.isControlsVisible
                ? Colors.black.withAlpha(150)
                : Colors.transparent,
            child: _dragging
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5.0)),
                        color: Colors.black.withAlpha(150),
                      ),
                      child: Text(
                        "$seekDuration ($seekPosition)",
                        style: const TextStyle(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),
          Center(
            child: Container(
                color: Colors.transparent,
                child: doubleTapDetector && tappedSide == true
                    ? skipIcon(Icons.fast_forward, distanceFromCenter)
                    : doubleTapDetector && tappedSide == false
                        ? skipIcon(Icons.fast_rewind, -distanceFromCenter)
                        : null),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _controller.value.isControlsVisible || showLockIcon
                ? IconButton(
                    icon: Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: Colors.white,
                    ),
                    onPressed: switchLock,
                  )
                : Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}
