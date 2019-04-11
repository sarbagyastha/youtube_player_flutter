import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/src/youtube_player.dart';

class ProgressBar extends StatefulWidget {
  ProgressBar(
    this.controller, {
    ProgressColors colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
  }) : colors = colors ?? ProgressColors();

  final YoutubePlayerController controller;
  final ProgressColors colors;
  final Function() onDragStart;
  final Function() onDragEnd;
  final Function() onDragUpdate;

  @override
  _ProgressBarState createState() {
    return _ProgressBarState();
  }
}

class _ProgressBarState extends State<ProgressBar> {
  _ProgressBarState() {
    listener = () {
      setState(() {});
    };
  }

  VoidCallback listener;
  bool _controllerWasPlaying = false;

  YoutubePlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final RenderBox box = context.findRenderObject();
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller.value.duration * relative;
      controller.seekTo(position);
    }

    return GestureDetector(
      child: (controller.value.hasError)
          ? Container()
          : Center(
              child: Container(
                height: 60.0,
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
                child: CustomPaint(
                  painter: _ProgressBarPainter(
                    controller.value,
                    widget.colors,
                  ),
                ),
              ),
            ),
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.isLoaded) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.isLoaded) {
          return;
        }
        seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying) {
          controller.play();
        }

        if (widget.onDragEnd != null) {
          widget.onDragEnd();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (!controller.value.isLoaded) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.value, this.colors);

  YoutubePlayerValue value;
  ProgressColors colors;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final height = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(size.width, size.height / 2 + height),
        ),
        Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (!value.isLoaded) {
      return;
    }
    double playedPartPercent =
        value.position.inMilliseconds / value.duration.inMilliseconds;
    if (playedPartPercent.isNaN) playedPartPercent = 0;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    final double end = value.buffered * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, size.height / 2),
          Offset(end, size.height / 2 + height),
        ),
        Radius.circular(4.0),
      ),
      colors.bufferedPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(playedPart, size.height / 2 + height),
        ),
        Radius.circular(4.0),
      ),
      colors.playedPaint,
    );
    canvas.drawCircle(
      Offset(playedPart, size.height / 2 + height / 2),
      height * 3,
      colors.handlePaint,
    );
  }
}

class ProgressColors {
  ProgressColors({
    Color playedColor: const Color.fromRGBO(255, 0, 0, 0.9),
    Color bufferedColor: const Color.fromRGBO(200, 200, 200, 0.9),
    Color handleColor: const Color.fromRGBO(255, 0, 0, 1.0),
    Color backgroundColor: const Color.fromRGBO(10, 10, 10, 0.5),
  })  : playedPaint = Paint()..color = playedColor,
        bufferedPaint = Paint()..color = bufferedColor,
        handlePaint = Paint()..color = handleColor,
        backgroundPaint = Paint()..color = backgroundColor;

  final Paint playedPaint;
  final Paint bufferedPaint;
  final Paint handlePaint;
  final Paint backgroundPaint;
}
