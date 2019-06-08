import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'youtube_player.dart';

class YoutubeScaffold extends StatefulWidget {
  final Widget child;

  YoutubeScaffold({@required this.child});

  @override
  _YoutubeScaffoldState createState() => _YoutubeScaffoldState();
}

class _YoutubeScaffoldState extends State<YoutubeScaffold>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (window.physicalSize.width > window.physicalSize.height) {
      youtubePlayerKey.currentState.controller.enterFullScreen(true);
    } else {
      youtubePlayerKey.currentState.controller.exitFullScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (youtubePlayerKey == null) {
      return widget.child;
    }
    if (youtubePlayerKey.currentState == null) {
      return widget.child;
    }
    if (youtubePlayerKey.currentState.controller == null) {
      return widget.child;
    } else if (youtubePlayerKey.currentState.controller.value.isFullScreen) {
      return Scaffold(
        body: youtubePlayerKey.currentState.widget,
      );
    }
    return widget.child;
  }
}
