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
      videoId: 'j4lDDQTKN8s',
      autoPlay: false,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.25, 0.6, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TitleBar(controller: widget.controller),
          Expanded(child: _PlayPauseCenter(controller: widget.controller)),
          _BottomControls(
            controller: widget.controller,
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
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.controller});

  final YoutubePlayerController controller;

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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 6, color: Colors.black)],
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
  const _PlayPauseCenter({required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: YoutubeValueBuilder(
        controller: controller,
        buildWhen: (o, n) => o.playerState != n.playerState,
        builder: (context, value) {
          if (value.playerState == PlayerState.buffering) {
            return const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            );
          }
          final isPlaying = value.playerState == PlayerState.playing;
          return IconButton(
            iconSize: 64,
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: Colors.white,
              shadows: const [Shadow(blurRadius: 12, color: Colors.black54)],
            ),
            onPressed: isPlaying ? controller.pauseVideo : controller.playVideo,
          );
        },
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.controller,
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
        final position =
            isSeeking ? Duration(seconds: seekValue.toInt()) : state.position;
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
                  Text(
                    fmt(position),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    fmt(duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                thumbColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                overlayColor: Colors.white24,
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
                      isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: onMuteToggle,
                  ),
                  const Spacer(),
                  FullscreenButton(controller: controller),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
