import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// A wrapper for [YoutubePlayer].
class YoutubePlayerBuilder extends StatefulWidget {
  /// The actual [YoutubePlayer].
  final YoutubePlayer player;

  /// Builds the widget below this [builder].
  final Widget Function(BuildContext, Widget) builder;

  /// Builder for [YoutubePlayer] that supports switching between fullscreen and normal mode.
  const YoutubePlayerBuilder({
    Key key,
    @required this.player,
    @required this.builder,
  }) : super(key: key);

  @override
  _YoutubePlayerBuilderState createState() => _YoutubePlayerBuilderState();
}

class _YoutubePlayerBuilderState extends State<YoutubePlayerBuilder>
    with WidgetsBindingObserver {
  final GlobalKey playerKey = GlobalKey();

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
    final physicalSize = SchedulerBinding.instance.window.physicalSize;
    final controller = widget.player.controller;
    if (physicalSize.width > physicalSize.height) {
      controller.updateValue(controller.value.copyWith(isFullScreen: true));
      SystemChrome.setEnabledSystemUIOverlays([]);
    } else {
      controller.updateValue(controller.value.copyWith(isFullScreen: false));
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    }
    super.didChangeMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final _player = Container(
      key: playerKey,
      child: WillPopScope(
        onWillPop: () async {
          final controller = widget.player.controller;
          if (controller.value.isFullScreen) {
            widget.player.controller.toggleFullScreenMode();
            return false;
          }
          return true;
        },
        child: widget.player,
      ),
    );
    final child = widget.builder(context, _player);
    return OrientationBuilder(
      builder: (context, orientation) =>
          orientation == Orientation.portrait ? child : _player,
    );
  }
}
