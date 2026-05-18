// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';

/// A widget which displays forward and rewind controls with double-tap gestures.
class ForwardRewindControls extends StatefulWidget {
  /// Creates [ForwardRewindControls] widget.
  const ForwardRewindControls({
    super.key,
    this.controller,
    this.rewindDuration = const Duration(seconds: 10),
    this.forwardDuration = const Duration(seconds: 10),
    this.tapShowDuration = const Duration(milliseconds: 500),
    this.controlsTimeOut = const Duration(seconds: 3),
  });

  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  /// Duration to rewind when double-tapped on left side.
  final Duration rewindDuration;

  /// Duration to forward when double-tapped on right side.
  final Duration forwardDuration;

  /// Duration to show button when double-tapped.
  final Duration tapShowDuration;

  /// Sets the timeout until when the controls hide.
  final Duration controlsTimeOut;

  @override
  State<ForwardRewindControls> createState() => _ForwardRewindControlsState();
}

class _ForwardRewindControlsState extends State<ForwardRewindControls> with TickerProviderStateMixin {
  late YoutubePlayerController _controller;
  late AnimationController _rewindAnimationController;
  late AnimationController _forwardAnimationController;
  Timer? _timer;

  bool _showRewindButton = false;
  bool _showForwardButton = false;
  bool _showInitialButtons = true;

  @override
  void initState() {
    super.initState();

    _rewindAnimationController = AnimationController(
      vsync: this,
      duration: widget.tapShowDuration,
    );

    _forwardAnimationController = AnimationController(
      vsync: this,
      duration: widget.tapShowDuration,
    );

    // Show initial buttons for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showInitialButtons = false;
        });
      }
    });
  }

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rewindAnimationController.dispose();
    _forwardAnimationController.dispose();
    super.dispose();
  }

  void _showRewindButtonAnimation() {
    setState(() {
      _showRewindButton = true;
    });
    _rewindAnimationController.reset();
    _rewindAnimationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _showRewindButton = false;
        });
      }
    });
  }

  void _showForwardButtonAnimation() {
    setState(() {
      _showForwardButton = true;
    });
    _forwardAnimationController.reset();
    _forwardAnimationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _showForwardButton = false;
        });
      }
    });
  }

  void _toggleControls() {
    _controller.updateValue(
      _controller.value.copyWith(
        isControlsVisible: !_controller.value.isControlsVisible,
      ),
    );
    _timer?.cancel();
    _timer = Timer(widget.controlsTimeOut, () {
      if (!_controller.value.isDragging) {
        _controller.updateValue(
          _controller.value.copyWith(
            isControlsVisible: false,
          ),
        );
      }
    });
  }

  void _rewind() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - widget.rewindDuration;
    final targetPosition = newPosition.isNegative ? Duration.zero : newPosition;

    _controller.seekTo(targetPosition);
    _showRewindButtonAnimation();
  }

  void _forward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + widget.forwardDuration;
    final maxDuration = _controller.metadata.duration;
    final targetPosition = newPosition > maxDuration ? maxDuration : newPosition;

    _controller.seekTo(targetPosition);
    _showForwardButtonAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left side - Rewind (smaller area to avoid blocking single taps)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          right: 0,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _rewind,
                  onTap: _toggleControls,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _forward,
                  onTap: _toggleControls,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              )
            ],
          ),
        ),

        // Rewind button
        if (_showRewindButton || _showInitialButtons)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showRewindButton ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(22.5),
                    ),
                    child: const Icon(
                      Icons.replay_10,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Forward button
        if (_showForwardButton || _showInitialButtons)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showForwardButton ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(22.5),
                    ),
                    child: const Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
