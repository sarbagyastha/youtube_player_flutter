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

class _PlayPauseButtonState extends State<PlayPauseButton>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;

  YoutubePlayerController ytController;

  YoutubePlayerController get controller => ytController;

  set controller(YoutubePlayerController c) => ytController = c;

  AnimationController _animController;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    _animController = AnimationController(
      vsync: this,
      value: 0,
      duration: Duration(milliseconds: 300),
    );
    _attachListenerToController();
    widget.showControls.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  _attachListenerToController() {
    controller.addListener(
      () {
        if (mounted) {
          setState(() {
            _isPlaying = controller.value.isPlaying;
          });
          if (controller.value.isPlaying) {
            _animController.forward();
          } else {
            _animController.reverse();
          }
        }
      },
    );
  }

  _animate() {}

  @override
  Widget build(BuildContext context) {
    if (controller.hashCode != widget.controller.hashCode) {
      controller = widget.controller;
      _attachListenerToController();
    }
    return controller.value.playerState == PlayerState.BUFFERING
        ? widget.bufferIndicator
        : Visibility(
            visible: widget.showControls.value ||
                controller.value.playerState == PlayerState.CUED ||
                !controller.value.isPlaying,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50.0),
                onTap: () {
                  _isPlaying ? controller.pause() : controller.play();
                  _animate();
                },
                child: AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: _animController.view,
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
  final bool hideFullScreenButton;

  BottomBar(
    this.controller,
    this.showControls,
    this.aspectRatio,
    this.progressColors,
    this.hideFullScreenButton,
  );

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int _currentPosition = 0;
  int _remainingDuration = 0;

  YoutubePlayerController ytController;

  YoutubePlayerController get controller => ytController;

  set controller(YoutubePlayerController c) => ytController = c;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    _attachListenerToController();
    widget.showControls.addListener(
      () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  _attachListenerToController() {
    controller.addListener(
      () {
        if (mounted) {
          setState(() {
            _currentPosition = controller.value.duration.inMilliseconds == 0
                ? 0
                : controller.value.position.inMilliseconds;
            _remainingDuration =
                controller.value.duration.inMilliseconds - _currentPosition;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.hashCode != widget.controller.hashCode) {
      controller = widget.controller;
      _attachListenerToController();
    }
    return Visibility(
      visible: widget.showControls.value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                controller,
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
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Colors.black,
            ),
            child: PopupMenuButton<PlaybackRate>(
              onSelected: controller.setPlaybackRate,
              child: Padding(
                padding: EdgeInsets.fromLTRB(8.0, 8.0, 0.0, 8.0),
                child: Image.asset(
                  'assets/speedometer.png',
                  package: 'youtube_player_flutter',
                  width: 20.0,
                  height: 20.0,
                  color: Colors.white,
                ),
              ),
              tooltip: 'PlayBack Rate',
              itemBuilder: (context) => [
                _popUpItem('2.0', PlaybackRate.DOUBLE),
                _popUpItem('1.5', PlaybackRate.ONE_AND_A_HALF),
                _popUpItem('1.0', PlaybackRate.NORMAL),
                _popUpItem('0.5', PlaybackRate.HALF),
                _popUpItem('0.25', PlaybackRate.QUARTER),
              ],
            ),
          ),
          widget.hideFullScreenButton
              ? SizedBox(width: 10)
              : IconButton(
                  icon: Icon(
                    controller.value.isFullScreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (controller.value.isFullScreen) {
                      controller.exitFullScreen();
                    } else {
                      controller.enterFullScreen();
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _popUpItem(String text, PlaybackRate rate) {
    return CheckedPopupMenuItem(
      checked: controller.value.playbackRate == rate,
      child: Text(text),
      value: rate,
    );
  }
}

class LiveBottomBar extends StatefulWidget {
  final YoutubePlayerController controller;
  final ValueNotifier<bool> showControls;
  final double aspectRatio;
  final Color liveUIColor;
  final bool hideFullScreenButton;

  LiveBottomBar(
    this.controller,
    this.showControls,
    this.aspectRatio,
    this.liveUIColor,
    this.hideFullScreenButton,
  );

  @override
  _LiveBottomBarState createState() => _LiveBottomBarState();
}

class _LiveBottomBarState extends State<LiveBottomBar> {
  int _currentPosition = 0;
  double _currentSliderPosition = 0.0;

  YoutubePlayerController ytController;

  YoutubePlayerController get controller => ytController;

  set controller(YoutubePlayerController c) => ytController = c;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    _attachListenerToController();
    widget.showControls.addListener(
      () {
        if (mounted) setState(() {});
      },
    );
  }

  _attachListenerToController() {
    controller.addListener(
      () {
        if (mounted) {
          setState(() {
            _currentPosition = controller.value.position.inMilliseconds;
            _currentSliderPosition =
                controller.value.duration.inMilliseconds == 0
                    ? 0
                    : controller.value.position.inMilliseconds /
                        controller.value.duration.inMilliseconds;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.hashCode != widget.controller.hashCode) {
      controller = widget.controller;
      _attachListenerToController();
    }
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
              child: Slider(
                value: _currentSliderPosition,
                onChanged: (value) {
                  controller.seekTo(
                    Duration(
                      milliseconds:
                          (controller.value.duration.inMilliseconds * value)
                              .round(),
                    ),
                  );
                },
                activeColor: widget.liveUIColor,
                inactiveColor: Colors.transparent,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
            ),
          ),
          InkWell(
            onTap: () => controller.seekTo(controller.value.duration),
            child: Material(
              color: widget.liveUIColor,
              child: Text(
                " LIVE ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          widget.hideFullScreenButton
              ? SizedBox(width: 10)
              : IconButton(
                  icon: Icon(
                    controller.value.isFullScreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    controller.value = controller.value
                        .copyWith(isFullScreen: !controller.value.isFullScreen);
                  },
                ),
        ],
      ),
    );
  }
}

class TouchShutter extends StatefulWidget {
  final YoutubePlayerController controller;
  final ValueNotifier<bool> showControls;
  final bool disableDragSeek;

  TouchShutter(
    this.controller,
    this.showControls,
    this.disableDragSeek,
  );

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

  @override
  void initState() {
    super.initState();
    widget.showControls.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.disableDragSeek
        ? GestureDetector(
            onTap: () => widget.showControls.value = !widget.showControls.value,
          )
        : GestureDetector(
            onTap: () => widget.showControls.value = !widget.showControls.value,
            onHorizontalDragStart: (details) {
              setState(() {
                _dragging = true;
              });
              dragStartPos = details.globalPosition.dx;
            },
            onHorizontalDragUpdate: (details) {
              delta = details.globalPosition.dx - dragStartPos;
              seekToPosition =
                  (widget.controller.value.position.inMilliseconds +
                          delta * 1000)
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
              widget.controller.seekTo(Duration(milliseconds: seekToPosition));
              setState(() {
                _dragging = false;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: widget.showControls.value
                    ? Colors.black.withAlpha(150)
                    : Colors.transparent,
              ),
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
