import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/videos.dart';
import '../utils/format.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/load_video_field.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_tile.dart';
import '../widgets/transport_controls.dart';
import '../widgets/video_header.dart';
import '../widgets/volume_control.dart';

/// A live stream. Its duration keeps growing; the gap between duration and
/// position is how far behind live the viewer is.
class const LivePage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Live stream',
    create: () => YoutubePlayerController.fromVideoId(
      videoId: liveVideoId,
      autoPlay: true,
      params: const YoutubePlayerParams(mute: true),
    ),
    children: const [
      VideoHeader(),
      SectionCard(
        title: 'Live',
        icon: Icons.sensors,
        note:
            'For live streams, the duration is the stream time so far. Seek '
            'back within the DVR window, or jump to the live edge.',
        child: _LivePanel(),
      ),
      SectionCard(
        title: 'Playback',
        icon: Icons.smart_display_outlined,
        child: Column(
          children: [TransportControls(), SizedBox(height: 8), VolumeControl()],
        ),
      ),
      SectionCard(
        title: 'Watch another stream',
        icon: Icons.live_tv,
        child: LoadVideoField(hint: 'youtube.com/live/… or a video id'),
      ),
    ],
  );
}

class const _LivePanel() extends StatelessWidget {
  /// Closer than this to the live edge counts as live.
  static const _liveThreshold = Duration(seconds: 15);

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    final theme = Theme.of(context);
    // Position ticks stop while paused; rebuild on state changes too.
    return YoutubeValueBuilder(
      buildWhen: (a, b) => a.playerState != b.playerState,
      builder: (context, value) => StreamBuilder<YoutubeVideoState>(
        stream: controller.videoStateStream,
        builder: (context, snapshot) {
          final duration = secondsToDuration(controller.duration);
          final position =
              snapshot.data?.position ??
              secondsToDuration(controller.currentTime);
          final behind = duration - position;
          final atEdge = behind < _liveThreshold;
          final playing = value.playerState.isActive;
          return Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                children: [
                  _LiveBadge(active: atEdge && playing),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      duration == .zero
                          ? 'Waiting for the stream…'
                          : atEdge
                          ? 'You are watching live'
                          : '${formatDuration(behind)} behind live',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatGrid(
                children: [
                  StatTile(
                    label: 'Stream time',
                    value: formatDuration(duration),
                    icon: Icons.timelapse,
                  ),
                  StatTile(
                    label: 'Position',
                    value: formatDuration(position),
                    icon: Icons.place_outlined,
                  ),
                  StatTile(
                    label: 'Buffered',
                    value:
                        '${((snapshot.data?.loadedFraction ?? 0) * 100).toStringAsFixed(1)} %',
                    icon: Icons.downloading,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => controller.seekTo(
                      seconds: math.max(0, controller.currentTime - 30),
                      allowSeekAhead: true,
                    ),
                    icon: const Icon(Icons.replay_30),
                    label: const Text('Rewind 30 s'),
                  ),
                  FilledButton.icon(
                    onPressed: atEdge
                        ? null
                        : () {
                            controller
                              ..seekTo(
                                seconds: controller.duration,
                                allowSeekAhead: true,
                              )
                              ..playVideo();
                          },
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Go live'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A red LIVE badge whose dot pulses while at the live edge.
class const _LiveBadge({required final bool active}) extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? const Color(0xFFE62117)
        : Theme.of(context).colorScheme.outline;
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: .circular(6)),
      child: Padding(
        padding: const .symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: .min,
          children: [
            FadeTransition(
              opacity: widget.active
                  ? Tween(begin: .3, end: 1.0).animate(_pulse)
                  : const AlwaysStoppedAnimation(1),
              child: const Icon(Icons.circle, size: 10, color: Colors.white),
            ),
            const SizedBox(width: 6),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: .w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
