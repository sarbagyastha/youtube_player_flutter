import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_player_iframe_example/widgets/player/video_position_seeker.dart';

class PlaybackTab extends StatefulWidget {
  const PlaybackTab({super.key});

  @override
  State<PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends State<PlaybackTab> {
  bool _isMuted = false;
  double _volume = 1.0;
  bool _isLooping = false;
  bool _isShuffled = false;
  bool _seedStarted = false;

  static const _speeds = [0.5, 1.0, 1.5, 2.0];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seedStarted) return;
    _seedStarted = true;
    final controller = context.ytController;
    Future.wait([controller.isMuted, controller.volume]).then((results) {
      if (!mounted) return;
      setState(() {
        _isMuted = results[0] as bool;
        _volume = ((results[1] as int) / 100.0).clamp(0.0, 1.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transport controls card
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.skip_previous_rounded),
                        onPressed: controller.previousVideo,
                        iconSize: 26,
                        tooltip: 'Previous',
                      ),
                      YoutubeValueBuilder(
                        buildWhen: (o, n) => o.playerState != n.playerState,
                        builder: (context, value) {
                          final isPlaying =
                              value.playerState == PlayerState.playing;
                          return FilledButton(
                            style: FilledButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(18),
                              minimumSize: Size.zero,
                              backgroundColor: cs.primary,
                            ),
                            onPressed: isPlaying
                                ? controller.pauseVideo
                                : controller.playVideo,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 36,
                                color: cs.onPrimary,
                                key: ValueKey(isPlaying),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: controller.nextVideo,
                        iconSize: 26,
                        tooltip: 'Next',
                      ),
                      IconButton.filledTonal(
                        icon: Icon(
                          _isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                        ),
                        onPressed: () {
                          setState(() => _isMuted = !_isMuted);
                          _isMuted ? controller.mute() : controller.unMute();
                        },
                        iconSize: 22,
                        tooltip: _isMuted ? 'Unmute' : 'Mute',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Seek slider
                  const VideoPositionSeeker(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Volume
          Row(
            children: [
              Icon(
                _volume == 0 ? Icons.volume_mute_rounded : Icons.volume_down_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              Expanded(
                child: Slider(
                  value: _volume,
                  onChanged: (v) {
                    setState(() => _volume = v);
                    controller.setVolume((v * 100).round());
                  },
                ),
              ),
              Icon(
                Icons.volume_up_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Speed
          Row(
            children: [
              Text(
                'Speed',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: YoutubeValueBuilder(
                  buildWhen: (o, n) => o.playbackRate != n.playbackRate,
                  builder: (context, value) {
                    final current = value.playbackRate;
                    final selected =
                        _speeds.contains(current) ? {current} : {1.0};
                    return SegmentedButton<double>(
                      segments: _speeds
                          .map(
                            (r) => ButtonSegment(
                              value: r,
                              label: Text(
                                r % 1 == 0 ? '${r.toInt()}x' : '${r}x',
                              ),
                            ),
                          )
                          .toList(),
                      selected: selected,
                      onSelectionChanged: (rates) =>
                          controller.setPlaybackRate(rates.first),
                      showSelectedIcon: false,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 20),

          // Loop & shuffle
          SwitchListTile.adaptive(
            title: const Text('Loop playlist'),
            value: _isLooping,
            onChanged: (v) {
              setState(() => _isLooping = v);
              controller.setLoop(loopPlaylists: v);
            },
          ),
          SwitchListTile.adaptive(
            title: const Text('Shuffle playlist'),
            value: _isShuffled,
            onChanged: (v) {
              setState(() => _isShuffled = v);
              controller.setShuffle(shufflePlaylists: v);
            },
          ),
        ],
      ),
    );
  }
}
