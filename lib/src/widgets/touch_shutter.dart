import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';
import '../utils/duration_formatter.dart';

/// A widget to display darkened translucent overlay, when video area is touched.
///
/// Also provides ability to seek video by dragging horizontally.
class TouchShutter extends StatefulWidget {
  final bool disableDragSeek;
  final Duration timeOut;

  TouchShutter({
    this.disableDragSeek,
    @required this.timeOut,
  });

  @override
  _TouchShutterState createState() => _TouchShutterState();
}

class _TouchShutterState extends State<TouchShutter> {
  double dragStartPos = 0.0;
  double delta = 0.0;
  int seekToPosition = 0;
  String seekDuration = "";
  String seekPosition = "";
  bool _dragging = false;
  Timer _timer;

  YoutubePlayerController controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller ??= YoutubePlayerController.of(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    _timer?.cancel();
    controller.updateValue(
      controller.value.copyWith(
        showControls: !controller.value.showControls,
      ),
    );
    _timer = Timer(
      widget.timeOut,
      () => controller.updateValue(
        controller.value.copyWith(
          showControls: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.disableDragSeek
        ? GestureDetector(onTap: _toggleControls)
        : GestureDetector(
            onTap: _toggleControls,
            onHorizontalDragStart: (details) {
              setState(() {
                _dragging = true;
              });
              dragStartPos = details.globalPosition.dx;
            },
            onHorizontalDragUpdate: (details) {
              controller.updateValue(
                controller.value.copyWith(
                  showControls: false,
                ),
              );
              delta = details.globalPosition.dx - dragStartPos;
              seekToPosition =
                  (controller.value.position.inMilliseconds + delta * 1000)
                      .round();
              setState(() {
                seekDuration = (delta < 0 ? "- " : "+ ") +
                    durationFormatter(
                        (delta < 0 ? -1 : 1) * (delta * 1000).round());
                if (seekToPosition < 0) seekToPosition = 0;
                seekPosition = durationFormatter(seekToPosition);
              });
            },
            onHorizontalDragEnd: (_) {
              controller.seekTo(Duration(milliseconds: seekToPosition));
              setState(() {
                _dragging = false;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              color: controller.value.showControls
                  ? Colors.black.withAlpha(150)
                  : Colors.transparent,
              child: _dragging
                  ? Center(
                      child: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                          color: Colors.black.withAlpha(150),
                        ),
                        child: Text(
                          "$seekDuration ($seekPosition)",
                          style: TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ),
          );
  }
}
