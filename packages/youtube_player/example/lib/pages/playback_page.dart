import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/videos.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/fullscreen_controls.dart';
import '../widgets/load_video_field.dart';
import '../widgets/rate_selector.dart';
import '../widgets/section_card.dart';
import '../widgets/seek_bar.dart';
import '../widgets/transport_controls.dart';
import '../widgets/video_header.dart';
import '../widgets/video_thumbnail.dart';
import '../widgets/volume_control.dart';

/// The core playback API: transport, seeking, volume, speed, fullscreen and
/// loading videos.
class const PlaybackPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Playback',
    // Autoplay needs mute on most platforms.
    create: () => YoutubePlayerController.fromVideoId(
      videoId: videoIds.first,
      autoPlay: true,
      params: const YoutubePlayerParams(mute: true),
      onLoadError: (error) => debugPrint('Load error: $error'),
    ),
    children: const [
      VideoHeader(),
      SectionCard(
        title: 'Playback',
        icon: Icons.smart_display_outlined,
        child: Column(
          children: [SeekBar(), _QuickActions(), TransportControls()],
        ),
      ),
      SectionCard(
        title: 'Volume',
        icon: Icons.graphic_eq,
        child: VolumeControl(),
      ),
      SectionCard(title: 'Speed', icon: Icons.speed, child: RateSelector()),
      SectionCard(
        title: 'Fullscreen',
        icon: Icons.fullscreen,
        note:
            'Presented by the platform. iPhone only allows the player\'s own '
            'fullscreen button.',
        child: FullscreenControls(),
      ),
      SectionCard(
        title: 'Up next',
        icon: Icons.video_library_outlined,
        child: _UpNext(),
      ),
      SectionCard(
        title: 'Load a video',
        icon: Icons.link,
        note: 'Watch, youtu.be, embed, shorts and live URLs all work.',
        child: LoadVideoField(),
      ),
    ],
  );
}

class const _QuickActions() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    return Padding(
      padding: const .symmetric(vertical: 8),
      child: Wrap(
        alignment: .center,
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.stop_rounded),
            label: const Text('Stop'),
            onPressed: controller.stopVideo,
          ),
          ActionChip(
            avatar: const Icon(Icons.restart_alt),
            label: const Text('Restart'),
            onPressed: () =>
                controller.seekTo(seconds: 0, allowSeekAhead: true),
          ),
          ActionChip(
            avatar: const Icon(Icons.content_cut),
            label: const Text('Clip 0:30 – 0:45'),
            onPressed: () => controller.loadVideoById(
              videoId: controller.metadata.videoId.isEmpty
                  ? videoIds.first
                  : controller.metadata.videoId,
              startSeconds: 30,
              endSeconds: 45,
            ),
          ),
        ],
      ),
    );
  }
}

class const _UpNext() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    return YoutubeValueBuilder(
      buildWhen: (a, b) => a.metaData.videoId != b.metaData.videoId,
      builder: (context, value) => VideoStrip(
        videoIds: videoIds,
        selectedIndex: videoIds.indexOf(value.metaData.videoId),
        onSelected: (i) => controller.loadVideoById(videoId: videoIds[i]),
      ),
    );
  }
}
