import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';
import '../../theme/youtube_player_theme.dart';
import 'fullscreen_button.dart';

/// Row of playback controls: prev | play-pause | next + volume + fullscreen.
class PlaybackControls extends StatefulWidget {
  const PlaybackControls({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls> {
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.isMuted.then((muted) {
      if (mounted) setState(() => _isMuted = muted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);
    final color = theme.controlsColor;

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, color: color),
          onPressed: () {
            widget.controller.previousVideo();
            OverlayControllerScope.of(context).resetTimer();
          },
        ),
        YoutubeValueBuilder(
          controller: widget.controller,
          buildWhen: (o, n) => o.playerState != n.playerState,
          builder: (context, value) {
            final isPlaying = value.playerState == PlayerState.playing;
            return IconButton(
              iconSize: 40,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  color: color,
                  size: 40,
                ),
              ),
              onPressed: () {
                isPlaying
                    ? widget.controller.pauseVideo()
                    : widget.controller.playVideo();
                OverlayControllerScope.of(context).resetTimer();
              },
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.skip_next_rounded, color: color),
          onPressed: () {
            widget.controller.nextVideo();
            OverlayControllerScope.of(context).resetTimer();
          },
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: color,
          ),
          onPressed: () {
            if (_isMuted) {
              widget.controller.unMute();
            } else {
              widget.controller.mute();
            }
            setState(() => _isMuted = !_isMuted);
            OverlayControllerScope.of(context).resetTimer();
          },
        ),
        FullscreenButton(controller: widget.controller),
      ],
    );
  }
}
