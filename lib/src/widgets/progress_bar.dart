import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/src/player/youtube_player.dart';

class ProgressBarColors {
  final Color backgroundColor;

  final Color playedColor;

  final Color bufferedColor;

  final Color handleColor;

  const ProgressBarColors({
    this.backgroundColor,
    this.playedColor,
    this.bufferedColor,
    this.handleColor,
  });
}

class ProgressBar extends StatefulWidget {
  final ProgressBarColors colors;
  final bool isExpanded;

  ProgressBar({
    this.colors,
    this.isExpanded = false,
  });

  @override
  _ProgressBarState createState() {
    return _ProgressBarState();
  }
}

class _ProgressBarState extends State<ProgressBar> {
  YoutubePlayerController _controller;

  Offset _touchPoint = Offset.zero;

  double _playedValue = 0.0;
  double _bufferedValue = 0.0;

  bool _touchDown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = YoutubePlayerController.of(context)
      ..addListener(positionListener);
  }

  @override
  void dispose() {
    _controller?.removeListener(positionListener);
    super.dispose();
  }

  void positionListener() {
    int _totalDuration = _controller.value.duration?.inMilliseconds;
    if (mounted && _totalDuration != null && _totalDuration != 0) {
      setState(() {
        _playedValue =
            _controller.value.position.inMilliseconds / _totalDuration;
        _bufferedValue = _controller.value.buffered;
      });
    }
  }

  void _setValue() {
    _playedValue = _touchPoint.dx / context.size.width;
  }

  void _checkTouchPoint() {
    if (_touchPoint.dx <= 0) {
      _touchPoint = Offset(0, _touchPoint.dy);
    }
    if (_touchPoint.dx >= context.size.width) {
      _touchPoint = Offset(context.size.width, _touchPoint.dy);
    }
  }

  void _seekToRelativePosition(Offset globalPosition) {
    final RenderBox box = context.findRenderObject();
    _touchPoint = box.globalToLocal(globalPosition);
    _checkTouchPoint();
    final double relative = _touchPoint.dx / box.size.width;
    final Duration position = _controller.value.duration * relative;
    _controller.seekTo(position);
  }

  Widget _buildBar() {
    return GestureDetector(
      onHorizontalDragDown: (details) {
        _seekToRelativePosition(details.globalPosition);
        setState(() {
          _setValue();
          _touchDown = true;
        });
        _controller.pause();
      },
      onHorizontalDragUpdate: (details) {
        _seekToRelativePosition(details.globalPosition);
        setState(() {
          _setValue();
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          _touchDown = false;
        });
        _controller.play();
      },
      child: Container(
        constraints: BoxConstraints.expand(height: 7.0 * 2),
        child: CustomPaint(
          painter: _ProgressBarPainter(
            progressWidth: 2.0,
            handleRadius: 7.0,
            playedValue: _playedValue,
            bufferedValue: _bufferedValue,
            colors: widget.colors,
            touchDown: _touchDown,
            themeData: Theme.of(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      widget.isExpanded ? Expanded(child: _buildBar()) : _buildBar();
}

class _ProgressBarPainter extends CustomPainter {
  final double progressWidth;
  final double handleRadius;
  final double playedValue;
  final double bufferedValue;
  final ProgressBarColors colors;
  final bool touchDown;
  final ThemeData themeData;

  _ProgressBarPainter({
    this.progressWidth,
    this.handleRadius,
    this.playedValue,
    this.bufferedValue,
    this.colors,
    this.touchDown,
    this.themeData,
  });

  @override
  bool shouldRepaint(_ProgressBarPainter old) {
    return playedValue != old.playedValue ||
        bufferedValue != old.bufferedValue ||
        touchDown != old.touchDown;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.square
      ..strokeWidth = progressWidth;

    final centerY = size.height / 2.0;
    final barLength = size.width - handleRadius * 2.0;

    final Offset startPoint = Offset(handleRadius, centerY);
    final Offset endPoint = Offset(size.width - handleRadius, centerY);
    final Offset progressPoint =
        Offset(barLength * playedValue + handleRadius, centerY);
    final Offset secondProgressPoint =
        Offset(barLength * bufferedValue + handleRadius, centerY);

    paint.color =
        colors?.backgroundColor ?? themeData.accentColor.withOpacity(0.38);
    canvas.drawLine(startPoint, endPoint, paint);

    paint.color = colors?.bufferedColor ?? Colors.white70;
    canvas.drawLine(startPoint, secondProgressPoint, paint);

    paint.color = colors?.playedColor ?? themeData.accentColor;
    canvas.drawLine(startPoint, progressPoint, paint);

    final Paint handlePaint = Paint()..isAntiAlias = true;

    handlePaint.color = Colors.transparent;
    canvas.drawCircle(progressPoint, centerY, handlePaint);

    final Color _handleColor = colors?.handleColor ?? themeData.accentColor;

    if (touchDown) {
      handlePaint.color = _handleColor.withOpacity(0.4);
      canvas.drawCircle(progressPoint, handleRadius * 2, handlePaint);
    }

    handlePaint.color = _handleColor;
    canvas.drawCircle(progressPoint, handleRadius, handlePaint);
  }
}
