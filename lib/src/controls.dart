import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/src/duration_formatter.dart';
import 'package:youtube_player_flutter/src/progress_bar.dart';
import 'package:youtube_player_flutter/src/youtube_player.dart';

class PlayPauseButton extends StatefulWidget {
  final YoutubePlayerController controller;
  final ValueNotifier<bool> showControls;
  final Widget bufferIndicator;

  PlayPauseButton(this.controller, this.showControls, this.bufferIndicator);

  @override
  _PlayPauseButtonState createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(
      () {
        if (mounted) {
          setState(() {
            _isPlaying = widget.controller.value.isPlaying;
          });
        }
      },
    );
    widget.showControls.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.controller.value.playerState == PlayerState.BUFFERING
        ? widget.bufferIndicator
        : Visibility(
            visible: widget.showControls.value ||
                widget.controller.value.playerState == PlayerState.CUED,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50.0),
                onTap: () {
                  _isPlaying
                      ? widget.controller.pause()
                      : widget.controller.play();
                },
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 60.0,
                ),
              ),
            ),
          );
  }
}

class BottomBar extends StatefulWidget {
  final YoutubePlayerController controller;
  final ValueNotifier<bool> showControls;
  final double aspectRatio;
  final ProgressColors progressColors;

  BottomBar(this.controller, this.showControls, this.aspectRatio,
      this.progressColors);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int _currentPosition = 0;
  int _remainingDuration = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(
      () {
        if (mounted) {
          setState(() {
            _currentPosition = widget.controller.value.position.inMilliseconds;
            _remainingDuration =
                widget.controller.value.duration.inMilliseconds -
                    _currentPosition;
          });
        }
      },
    );
    widget.showControls.addListener(
      () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.showControls.value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 14.0,
          ),
          Text(
            durationFormatter(_currentPosition),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.0,
            ),
          ),
          Expanded(
            child: Padding(
              child: ProgressBar(
                widget.controller,
                colors: widget.progressColors,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
            ),
          ),
          Text(
            "- ${durationFormatter(_remainingDuration)}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.0,
            ),
          ),
          IconButton(
            icon: Icon(
              widget.controller.value.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: () {
              widget.controller.value = widget.controller.value.copyWith(
                  isFullScreen: !widget.controller.value.isFullScreen);
            },
          ),
        ],
      ),
    );
  }
}

class TouchShutter extends StatefulWidget {
  final ValueNotifier<bool> showControls;

  TouchShutter(this.showControls);

  @override
  _TouchShutterState createState() => _TouchShutterState();
}

class _TouchShutterState extends State<TouchShutter> {
  @override
  void initState() {
    super.initState();
    widget.showControls.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.showControls.value = !widget.showControls.value,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.showControls.value
              ? Colors.black.withAlpha(120)
              : Colors.transparent,
        ),
      ),
    );
  }
}
