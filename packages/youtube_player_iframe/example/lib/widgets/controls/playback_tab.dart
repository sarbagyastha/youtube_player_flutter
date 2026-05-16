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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transport controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: controller.previousVideo,
                tooltip: 'Previous',
              ),
              YoutubeValueBuilder(
                buildWhen: (o, n) => o.playerState != n.playerState,
                builder: (context, value) {
                  final isPlaying = value.playerState == PlayerState.playing;
                  return IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 36,
                    onPressed: isPlaying
                        ? controller.pauseVideo
                        : controller.playVideo,
                    tooltip: isPlaying ? 'Pause' : 'Play',
                  );
                },
              ),
              IconButton(
                icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                onPressed: () {
                  setState(() => _isMuted = !_isMuted);
                  _isMuted ? controller.mute() : controller.unMute();
                },
                tooltip: _isMuted ? 'Unmute' : 'Mute',
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: controller.nextVideo,
                tooltip: 'Next',
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Seek slider
          const VideoPositionSeeker(),

          const SizedBox(height: 8),

          // Volume slider
          Row(
            children: [
              Icon(
                _volume == 0 ? Icons.volume_mute : Icons.volume_down,
                size: 20,
              ),
              Expanded(
                child: Slider(
                  value: _volume,
                  onChanged: (v) {
                    setState(() => _volume = v);
                    controller.setVolume((v * 100).round());
                  },
                  min: 0,
                  max: 1,
                ),
              ),
              Icon(Icons.volume_up, size: 20),
            ],
          ),

          const SizedBox(height: 4),

          // Playback speed
          Row(
            children: [
              Text(
                'Speed',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 12),
              YoutubeValueBuilder(
                buildWhen: (o, n) => o.playbackRate != n.playbackRate,
                builder: (context, value) {
                  return DropdownButton<double>(
                    value: value.playbackRate,
                    isDense: true,
                    underline: const SizedBox(),
                    items: PlaybackRate.all
                        .map(
                          (rate) => DropdownMenuItem(
                            value: rate,
                            child: Text(
                              '${rate}x',
                              style: const TextStyle(
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (rate) {
                      if (rate != null) controller.setPlaybackRate(rate);
                    },
                  );
                },
              ),
            ],
          ),

          const Divider(height: 24),

          // Loop toggle
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Loop playlist'),
            value: _isLooping,
            onChanged: (v) {
              setState(() => _isLooping = v);
              controller.setLoop(loopPlaylists: v);
            },
          ),

          // Shuffle toggle
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
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
