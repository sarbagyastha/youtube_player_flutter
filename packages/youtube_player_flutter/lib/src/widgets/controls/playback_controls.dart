import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';

/// Three centered circular buttons: previous | play-pause | next.
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleButton(
          icon: Icons.skip_previous_rounded,
          onTap: () {
            controller.previousVideo();
            OverlayControllerScope.of(context).resetTimer();
          },
        ),
        const SizedBox(width: 16),
        YoutubeValueBuilder(
          controller: controller,
          buildWhen: (o, n) => o.playerState != n.playerState,
          builder: (context, value) {
            final isPlaying = value.playerState == PlayerState.playing;
            return _AnimatedPlayPauseButton(
              isPlaying: isPlaying,
              onTap: () {
                isPlaying
                    ? controller.pauseVideo()
                    : controller.playVideo();
                OverlayControllerScope.of(context).resetTimer();
              },
            );
          },
        ),
        const SizedBox(width: 16),
        _CircleButton(
          icon: Icons.skip_next_rounded,
          onTap: () {
            controller.nextVideo();
            OverlayControllerScope.of(context).resetTimer();
          },
        ),
      ],
    );
  }
}

class _AnimatedPlayPauseButton extends StatefulWidget {
  const _AnimatedPlayPauseButton({
    required this.isPlaying,
    required this.onTap,
  });

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  State<_AnimatedPlayPauseButton> createState() =>
      _AnimatedPlayPauseButtonState();
}

class _AnimatedPlayPauseButtonState extends State<_AnimatedPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isPlaying ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(_AnimatedPlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      widget.isPlaying
          ? _animController.forward()
          : _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: Center(
          child: SizedBox.square(
            dimension: 56,
            child: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _animController,
              color: Colors.white,
              size: 54,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
