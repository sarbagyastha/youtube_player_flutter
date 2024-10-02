// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';

/// A widget to display the full screen toggle button.
class FullScreenButton extends StatefulWidget {
  /// Creates [FullScreenButton] widget.
  const FullScreenButton({
    super.key,
    this.controller,
    this.color = Colors.white,
  });

  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  /// Defines color of the button.
  final Color color;

  @override
  State<FullScreenButton> createState() => _FullScreenButtonState();
}

class _FullScreenButtonState extends State<FullScreenButton> {
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
    return IconButton(
      icon: Icon(
        _controller.value.isFullScreen
            ? Icons.fullscreen_exit
            : Icons.fullscreen,
        color: widget.color,
      ),
      onPressed: () => _controller.toggleFullScreenMode(),
    );
  }
}
