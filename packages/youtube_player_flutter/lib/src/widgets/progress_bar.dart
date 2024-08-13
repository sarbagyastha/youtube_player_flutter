// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';

/// Defines different colors for [ProgressBar].
class ProgressBarColors {
  /// Defines background color of the [ProgressBar].
  final Color? backgroundColor;

  /// Defines color for played portion of the [ProgressBar].
  final Color? playedColor;

  /// Defines color for buffered portion of the [ProgressBar].
  final Color? bufferedColor;

  /// Defines color for handle of the [ProgressBar].
  final Color? handleColor;

  /// Creates [ProgressBarColors].
  const ProgressBarColors({
    this.backgroundColor,
    this.playedColor,
    this.bufferedColor,
    this.handleColor,
  });

  ///
  ProgressBarColors copyWith({
    Color? backgroundColor,
    Color? playedColor,
    Color? bufferedColor,
    Color? handleColor,
  }) =>
      ProgressBarColors(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        handleColor: handleColor ?? this.handleColor,
        bufferedColor: bufferedColor ?? this.bufferedColor,
        playedColor: playedColor ?? this.playedColor,
      );
}

/// A widget to display video progress bar.
class ProgressBar extends StatefulWidget {
  /// Creates [ProgressBar] widget.
  const ProgressBar({
    super.key,
    this.controller,
    this.colors,
    this.isExpanded = false,
  });

  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  /// Defines colors for the progress bar.
  final ProgressBarColors? colors;

  /// Set true to get expanded [ProgressBar].
  ///
  /// Default is false.
  final bool isExpanded;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  late YoutubePlayerController _controller;

  Offset _touchPoint = Offset.zero;

  double _playedValue = 0.0;
  double _bufferedValue = 0.0;

  bool _touchDown = false;
  late Duration _position;

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
    _controller.addListener(positionListener);
    positionListener();
  }

  @override
  void dispose() {
    _controller.removeListener(positionListener);
    super.dispose();
  }

  void positionListener() {
    var totalDuration = _controller.metadata.duration.inMilliseconds;
    if (mounted && !totalDuration.isNaN && totalDuration != 0) {
      setState(() {
        _playedValue =
            _controller.value.position.inMilliseconds / totalDuration;
        _bufferedValue = _controller.value.buffered;
      });
    }
  }

  void _setValue() {
    _playedValue = _touchPoint.dx / context.size!.width;
  }

  void _checkTouchPoint() {
    if (_touchPoint.dx <= 0) {
      _touchPoint = Offset(0, _touchPoint.dy);
    }
    if (_touchPoint.dx >= context.size!.width) {
      _touchPoint = Offset(context.size!.width, _touchPoint.dy);
    }
  }

  void _seekToRelativePosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    _touchPoint = box.globalToLocal(globalPosition);
    _checkTouchPoint();
    final relative = _touchPoint.dx / box.size.width;
    _position = _controller.metadata.duration * relative;
    _controller.seekTo(_position, allowSeekAhead: false);
  }

  void _dragEndActions() {
    _controller.updateValue(
      _controller.value.copyWith(isControlsVisible: false, isDragging: false),
    );
    _controller.seekTo(_position, allowSeekAhead: true);
    setState(() {
      _touchDown = false;
    });
    _controller.play();
  }

  Widget _buildBar() {
    return GestureDetector(
      onHorizontalDragDown: (details) {
        _controller.updateValue(
          _controller.value.copyWith(isControlsVisible: true, isDragging: true),
        );
        _seekToRelativePosition(details.globalPosition);
        setState(() {
          _setValue();
          _touchDown = true;
        });
      },
      onHorizontalDragUpdate: (details) {
        _seekToRelativePosition(details.globalPosition);
        setState(_setValue);
      },
      onHorizontalDragEnd: (details) {
        _dragEndActions();
      },
      onHorizontalDragCancel: _dragEndActions,
      child: Container(
        color: Colors.transparent,
        constraints: const BoxConstraints.expand(height: 7.0 * 2),
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
  final ProgressBarColors? colors;
  final bool touchDown;
  final ThemeData themeData;

  _ProgressBarPainter({
    required this.progressWidth,
    required this.handleRadius,
    required this.playedValue,
    required this.bufferedValue,
    this.colors,
    required this.touchDown,
    required this.themeData,
  });

  @override
  bool shouldRepaint(_ProgressBarPainter old) {
    return playedValue != old.playedValue ||
        bufferedValue != old.bufferedValue ||
        touchDown != old.touchDown;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.square
      ..strokeWidth = progressWidth;

    final centerY = size.height / 2.0;
    final barLength = size.width - handleRadius * 2.0;

    final startPoint = Offset(handleRadius, centerY);
    final endPoint = Offset(size.width - handleRadius, centerY);
    final progressPoint = Offset(
      barLength * playedValue + handleRadius,
      centerY,
    );
    final secondProgressPoint = Offset(
      barLength * bufferedValue + handleRadius,
      centerY,
    );

    final color = themeData.colorScheme.primaryContainer;

    paint.color = colors?.backgroundColor ?? color.withOpacity(0.38);
    canvas.drawLine(startPoint, endPoint, paint);

    paint.color = colors?.bufferedColor ?? Colors.white70;
    canvas.drawLine(startPoint, secondProgressPoint, paint);

    paint.color = colors?.playedColor ?? color;
    canvas.drawLine(startPoint, progressPoint, paint);

    final handlePaint = Paint()..isAntiAlias = true;

    handlePaint.color = Colors.transparent;
    canvas.drawCircle(progressPoint, centerY, handlePaint);

    final handleColor = colors?.handleColor ?? color;

    if (touchDown) {
      handlePaint.color = handleColor.withOpacity(0.4);
      canvas.drawCircle(progressPoint, handleRadius * 3, handlePaint);
    }

    handlePaint.color = handleColor;
    canvas.drawCircle(progressPoint, handleRadius, handlePaint);
  }
}
