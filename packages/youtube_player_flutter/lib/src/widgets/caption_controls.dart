// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';

/// A widget which displays caption toggle controls in the video player.
class CaptionControls extends StatefulWidget {
  /// Creates [CaptionControls] widget.
  const CaptionControls({
    super.key,
    this.controller,
    this.iconColor = Colors.white,
    this.iconSize = 22.0,
    this.onCaptionToggle,
  });

  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  /// Color of the caption icon.
  final Color iconColor;

  /// Size of the caption icon.
  final double iconSize;

  /// Callback when caption is toggled.
  final VoidCallback? onCaptionToggle;

  @override
  State<CaptionControls> createState() => _CaptionControlsState();
}

class _CaptionControlsState extends State<CaptionControls> {
  late YoutubePlayerController _controller;
  bool _isCaptionsEnabled = false;
  bool _isVisible = true;

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

    // Initialize caption state
    _isCaptionsEnabled = _controller.flags.enableCaption;

    // Listen to controller changes to show/hide controls
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        _isVisible = _controller.value.isControlsVisible;
      });
    }
  }

  void _toggleCaptions() {
    setState(() {
      _isCaptionsEnabled = !_isCaptionsEnabled;
    });

    if (_isCaptionsEnabled) {
      _controller.showCaptions();
    } else {
      _controller.hideCaptions();
    }

    widget.onCaptionToggle?.call();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: _toggleCaptions,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _isCaptionsEnabled ? Icons.closed_caption : Icons.closed_caption_off,
              color: widget.iconColor,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
