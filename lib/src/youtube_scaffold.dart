/*
import 'dart:ui';

import 'package:flutter/material.dart';
import 'youtube_player.dart';

class YoutubeScaffold extends StatefulWidget {
  final Widget child;

  /// Rotating the device to landscape will switch to fullscreen.
  final bool fullScreenOnOrientationChange;

  YoutubeScaffold({
    @required this.child,
    this.fullScreenOnOrientationChange = true,
  });

  @override
  _YoutubeScaffoldState createState() => _YoutubeScaffoldState();
}

class _YoutubeScaffoldState extends State<YoutubeScaffold>
    with WidgetsBindingObserver {
  YoutubePlayerController _controller;
  bool _justChanged = false;

  @override
  void initState() {
    super.initState();
    _controller = youtubePlayerKey?.currentState?.controller;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void deactivate() {
    youtubePlayerKey.currentState.deactivate();
    super.deactivate();
  }

  @override
  void didChangeMetrics() {
    if (widget.fullScreenOnOrientationChange && !triggeredFullScreenByButton) {
      if (window.physicalSize.width > window.physicalSize.height &&
          !_controller.value.isFullScreen) {
        _controller.enterFullScreen(true);
      }
      if (window.physicalSize.width < window.physicalSize.height &&
          _controller.value.isFullScreen) {
        _controller.exitFullScreen();
      }
    }
    super.didChangeMetrics();
  }

  @override
  Widget build(BuildContext context) {
    _controller = youtubePlayerKey?.currentState?.controller;
    if (_controller != null) {
      if (_controller.value.isFullScreen) {
        return Scaffold(
          body: youtubePlayerKey.currentState.widget,
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: false,
        );
      }
    }
    return widget.child;
  }
}
*/
