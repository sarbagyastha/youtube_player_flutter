// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:material_ui/material_ui.dart';
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

class _CustomControls extends StatelessWidget {
  const _CustomControls({required this.controller});

  final YoutubePlayerController controller;

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
            child: _PlayPauseCenter(controller: controller, theme: theme),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TitleBar(controller: controller, theme: theme),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomControls(controller: controller, theme: theme),
          ),
        ],
      ),
    );
  }
}

String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
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
  const _BottomControls({required this.controller, required this.theme});

  final YoutubePlayerController controller;
  final YoutubePlayerThemeResolver theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Only the seek row follows position ticks.
        _SeekRow(controller: controller, theme: theme),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              YoutubeValueBuilder(
                controller: controller,
                buildWhen: (o, n) => o.isMuted != n.isMuted,
                builder: (context, value) => IconButton(
                  icon: Icon(
                    value.isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: theme.progressBarActiveColor,
                    size: 22,
                  ),
                  onPressed: value.isMuted
                      ? controller.unMute
                      : controller.mute,
                ),
              ),
              const Spacer(),
              Builder(
                builder: (context) {
                  final fullScreen = YoutubeFullScreen.of(context);
                  return IconButton(
                    icon: Icon(
                      fullScreen.isFullScreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      color: theme.progressBarActiveColor,
                    ),
                    onPressed: fullScreen.toggle,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Time labels and seek slider.
///
/// While dragging, only the local value changes; the player seeks once on
/// release instead of on every pointer move.
class _SeekRow extends StatefulWidget {
  const _SeekRow({required this.controller, required this.theme});

  final YoutubePlayerController controller;
  final YoutubePlayerThemeResolver theme;

  @override
  State<_SeekRow> createState() => _SeekRowState();
}

class _SeekRowState extends State<_SeekRow> {
  /// The slider position while dragging, in seconds; `null` otherwise.
  double? _dragSeconds;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = widget.theme;

    return StreamBuilder<YoutubeVideoState>(
      stream: controller.videoStateStream,
      builder: (context, snapshot) {
        // Ticks only arrive while playing; start from the last known position.
        final played =
            snapshot.data?.position ??
            Duration(microseconds: (controller.currentTime * 1e6).round());
        final duration = controller.metadata.duration;
        final totalSeconds = duration.inMicroseconds / 1e6;
        final seconds = (_dragSeconds ?? played.inMicroseconds / 1e6).clamp(
          0.0,
          totalSeconds > 0 ? totalSeconds : 0.0,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _fmt(Duration(seconds: seconds.floor())),
                    style: theme.timerStyle,
                  ),
                  const Spacer(),
                  Text(_fmt(duration), style: theme.timerStyle),
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
                value: seconds,
                max: totalSeconds > 0 ? totalSeconds : 1,
                onChanged: (v) => setState(() => _dragSeconds = v),
                onChangeEnd: (v) {
                  controller.seekTo(seconds: v, allowSeekAhead: true);
                  setState(() => _dragSeconds = null);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
