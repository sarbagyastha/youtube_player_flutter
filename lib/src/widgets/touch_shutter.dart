import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/duration_formatter.dart';
import '../utils/youtube_player_controller.dart';

/// A widget to display darkened translucent overlay, when video area is touched.
///
/// Also provides ability to seek video by dragging horizontally.
class TouchShutter extends StatefulWidget {
  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController controller;

  /// If true, disables the drag to seek functionality.
  ///
  /// Default is false.
  final bool disableDragSeek;

  /// Sets the timeout until when the controls hide.
  final Duration timeOut;

  TouchShutter({
    this.controller,
    this.disableDragSeek = false,
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    _controller.updateValue(
      _controller.value.copyWith(
        showControls: !_controller.value.showControls,
      ),
    );
    _timer?.cancel();
    _timer = Timer(widget.timeOut, () {
      if (!_controller.value.isDragging) {
        _controller.updateValue(
          _controller.value.copyWith(
            showControls: false,
          ),
        );
      }
    });
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
              _controller.updateValue(
                _controller.value.copyWith(
                  showControls: false,
                ),
              );
              delta = details.globalPosition.dx - dragStartPos;
              seekToPosition =
                  (_controller.value.position.inMilliseconds + delta * 1000)
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
              _controller.seekTo(Duration(milliseconds: seekToPosition));
              setState(() {
                _dragging = false;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              color: _controller.value.showControls
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
