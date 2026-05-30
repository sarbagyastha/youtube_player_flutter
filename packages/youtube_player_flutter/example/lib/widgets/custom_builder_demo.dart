// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CustomBuilderDemo extends StatefulWidget {
  const CustomBuilderDemo({super.key});

  @override
  State<CustomBuilderDemo> createState() => _CustomBuilderDemoState();
}

class _CustomBuilderDemoState extends State<CustomBuilderDemo> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: 'tcodrIK2P_I',
      autoPlay: false,
      startSeconds: 80,
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      builder: (context, player, ctrl) => Stack(
        children: [
          AbsorbPointer(child: player),
          Positioned.fill(child: _CustomControls(controller: ctrl)),
        ],
      ),
    );
  }
}

class _CustomControls extends StatefulWidget {
  const _CustomControls({required this.controller});

  final YoutubePlayerController controller;

  @override
  State<_CustomControls> createState() => _CustomControlsState();
}

class _CustomControlsState extends State<_CustomControls> {
  bool _isMuted = false;
  bool _isSeeking = false;
  double _seekValue = 0;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);
    final ext = Theme.of(context).extension<YoutubePlayerTheme>();

    // Respect a custom controlsBackgroundGradient if set; otherwise use the
    // standard dark-edges overlay that works on any video content.
    final gradient =
        ext?.controlsBackgroundGradient ??
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.25, 0.6, 1.0],
        );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Center(
            child: _PlayPauseCenter(
              controller: widget.controller,
              theme: theme,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TitleBar(controller: widget.controller, theme: theme),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomControls(
              controller: widget.controller,
              theme: theme,
              isMuted: _isMuted,
              isSeeking: _isSeeking,
              seekValue: _seekValue,
              fmt: _fmt,
              onMuteToggle: () {
                if (_isMuted) {
                  widget.controller.unMute();
                } else {
                  widget.controller.mute();
                }
                setState(() => _isMuted = !_isMuted);
              },
              onSeekStart: () => setState(() => _isSeeking = true),
              onSeekChanged: (v) => setState(() => _seekValue = v),
              onSeekEnd: () => setState(() => _isSeeking = false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.controller, required this.theme});

  final YoutubePlayerController controller;
  final YoutubePlayerThemeResolver theme;

  @override
  Widget build(BuildContext context) {
    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.metaData != n.metaData,
      builder: (context, value) {
        final title = value.metaData.title;
        if (title.isEmpty) return const SizedBox(height: 40);
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Text(
            title,
            style: theme.titleStyle.copyWith(
              shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

class _PlayPauseCenter extends StatelessWidget {
  const _PlayPauseCenter({required this.controller, required this.theme});

  final YoutubePlayerController controller;
  final YoutubePlayerThemeResolver theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: YoutubeValueBuilder(
        controller: controller,
        buildWhen: (o, n) => o.playerState != n.playerState,
        builder: (context, value) {
          if (value.playerState == PlayerState.buffering) {
            return SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: theme.progressBarActiveColor,
                strokeWidth: 2.5,
              ),
            );
          }
          final isPlaying = value.playerState == PlayerState.playing;
          return Material(
            color: theme.progressBarBackgroundColor,
            shape: const CircleBorder(),
            child: GestureDetector(
              onTap: isPlaying ? controller.pauseVideo : controller.playVideo,
              child: Icon(
                isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                color: theme.progressBarActiveColor,
                size: 64,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.controller,
    required this.theme,
    required this.isMuted,
    required this.isSeeking,
    required this.seekValue,
    required this.fmt,
    required this.onMuteToggle,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
  });

  final YoutubePlayerController controller;
  final YoutubePlayerThemeResolver theme;
  final bool isMuted;
  final bool isSeeking;
  final double seekValue;
  final String Function(Duration) fmt;
  final VoidCallback onMuteToggle;
  final VoidCallback onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final VoidCallback onSeekEnd;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<YoutubeVideoState>(
      stream: controller.videoStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const YoutubeVideoState();
        final duration = controller.metadata.duration;
        final totalSeconds = duration.inSeconds.toDouble();
        final position = isSeeking
            ? Duration(seconds: seekValue.toInt())
            : state.position;
        final sliderValue = totalSeconds > 0
            ? position.inSeconds.toDouble().clamp(0.0, totalSeconds)
            : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(fmt(position), style: theme.timerStyle),
                  const Spacer(),
                  Text(fmt(duration), style: theme.timerStyle),
                ],
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: theme.progressBarActiveColor,
                thumbColor: theme.progressBarActiveColor,
                inactiveTrackColor: theme.progressBarBackgroundColor,
                secondaryActiveTrackColor: theme.progressBarBufferedColor,
                overlayColor: theme.progressBarActiveColor.withValues(
                  alpha: 0.2,
                ),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(
                value: sliderValue,
                max: totalSeconds > 0 ? totalSeconds : 1,
                onChangeStart: (_) => onSeekStart(),
                onChanged: (v) {
                  onSeekChanged(v);
                  controller.seekTo(seconds: v, allowSeekAhead: false);
                },
                onChangeEnd: (v) {
                  controller.seekTo(seconds: v, allowSeekAhead: true);
                  onSeekEnd();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: theme.progressBarActiveColor,
                      size: 22,
                    ),
                    onPressed: onMuteToggle,
                  ),
                  const Spacer(),
                  YoutubeValueBuilder(
                    controller: controller,
                    buildWhen: (o, n) =>
                        o.fullScreenOption != n.fullScreenOption,
                    builder: (context, value) => IconButton(
                      icon: Icon(
                        value.fullScreenOption.enabled
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: theme.progressBarActiveColor,
                      ),
                      onPressed: controller.toggleFullScreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
