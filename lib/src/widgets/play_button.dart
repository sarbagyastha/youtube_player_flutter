import 'package:flutter/material.dart';

import '../enums/player_state.dart';
import '../utils/youtube_player_controller.dart';

/// A widget to display play/pause button.
class PlayPauseButton extends StatefulWidget {
  final Widget bufferIndicator;

  PlayPauseButton({
    this.bufferIndicator,
  });

  @override
  _PlayPauseButtonState createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton>
    with SingleTickerProviderStateMixin {
  YoutubePlayerController _controller;
  AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      value: 0,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= YoutubePlayerController.of(context)
      ..addListener(_playPauseListener);
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller?.removeListener(_playPauseListener);
    super.dispose();
  }

  void _playPauseListener() => _controller.value.isPlaying
      ? _animController.forward()
      : _animController.reverse();

  @override
  Widget build(BuildContext context) {
    if (_controller.value.playerState == PlayerState.buffering ||
        _controller.value.playerState == PlayerState.unknown) {
      return widget.bufferIndicator ??
          Container(
            width: 70.0,
            height: 70.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          );
    } else {
      return Visibility(
        visible: _controller.value.playerState == PlayerState.cued ||
            !_controller.value.isPlaying ||
            _controller.value.showControls,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50.0),
            onTap: () => _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play(),
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
}
