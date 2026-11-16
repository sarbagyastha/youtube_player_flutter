import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

void main() => runApp(const ExampleApp());

const _videos = ['dQw4w9WgXcQ', 'jNQXAC9IVRw', 'aqz-KE-bpKQ', 'M7lc1UVf-VE'];

class const ExampleApp({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'youtube_player',
    theme: ThemeData(colorSchemeSeed: const Color(0xFFFF0000)),
    darkTheme: ThemeData(
      colorSchemeSeed: const Color(0xFFFF0000),
      brightness: .dark,
    ),
    home: const PlayerPage(),
  );
}

class const PlayerPage({super.key}) extends StatefulWidget {
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _videos.first,
      autoPlay: true,
      params: const YoutubePlayerParams(mute: true),
      onLoadError: (error) => debugPrint('Load error: $error'),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YoutubePlayerControllerProvider(
    controller: _controller,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('youtube_player'),
        actions: [
          IconButton(
            tooltip: 'List of players',
            icon: const Icon(Icons.view_list),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const ListPage())),
          ),
        ],
      ),
      body: ListView(
        children: [
          YoutubePlayer(controller: _controller),
          const _Info(),
          const _Progress(),
          const _Controls(),
          const _LoadField(),
        ],
      ),
    ),
  );
}

class const _Info() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => YoutubeValueBuilder(
    builder: (context, value) => ListTile(
      title: Text(
        value.metaData.title.isEmpty ? 'Loading…' : value.metaData.title,
      ),
      subtitle: Text(
        '${value.metaData.author} · ${value.playerState.name} · '
        '${value.playbackRate}x'
        '${value.hasError ? ' · ${value.error.name}' : ''}',
      ),
    ),
  );
}

class const _Progress() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    return StreamBuilder<YoutubeVideoState>(
      stream: controller.videoStateStream,
      initialData: const YoutubeVideoState(),
      builder: (context, snapshot) {
        final duration = controller.metadata.duration.inMilliseconds;
        final position = snapshot.requireData.position.inMilliseconds;
        return Slider(
          value: duration == 0 ? 0 : (position / duration).clamp(0, 1),
          secondaryTrackValue: snapshot.requireData.loadedFraction,
          onChanged: duration == 0
              ? null
              : (v) => controller.seekTo(seconds: v * duration / 1000),
          onChangeEnd: duration == 0
              ? null
              : (v) => controller.seekTo(
                  seconds: v * duration / 1000,
                  allowSeekAhead: true,
                ),
        );
      },
    );
  }
}

class const _Controls() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    return YoutubeValueBuilder(
      builder: (context, value) => Wrap(
        alignment: .center,
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Previous',
            icon: const Icon(Icons.skip_previous),
            onPressed: controller.previousVideo,
          ),
          IconButton.filled(
            tooltip: value.playerState == .playing ? 'Pause' : 'Play',
            icon: Icon(
              value.playerState == .playing ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: value.playerState == .playing
                ? controller.pauseVideo
                : controller.playVideo,
          ),
          IconButton(
            tooltip: 'Next',
            icon: const Icon(Icons.skip_next),
            onPressed: controller.nextVideo,
          ),
          IconButton(
            tooltip: 'Toggle mute',
            icon: const Icon(Icons.volume_up),
            onPressed: () async => await controller.isMuted
                ? controller.unMute()
                : controller.mute(),
          ),
          PopupMenuButton<double>(
            tooltip: 'Playback rate',
            icon: const Icon(Icons.speed),
            onSelected: controller.setPlaybackRate,
            itemBuilder: (_) => [
              for (final rate in PlaybackRate.all)
                CheckedPopupMenuItem(
                  value: rate,
                  checked: rate == value.playbackRate,
                  child: Text('${rate}x'),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Fullscreen',
            icon: const Icon(Icons.fullscreen),
            onPressed: () async {
              final accepted = await controller.enterFullScreen();
              if (!accepted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Use the fullscreen button in the player.'),
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Load playlist',
            icon: const Icon(Icons.playlist_play),
            onPressed: () => controller.loadPlaylist(list: _videos),
          ),
        ],
      ),
    );
  }
}

class const _LoadField() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(16),
    child: TextField(
      decoration: const InputDecoration(
        labelText: 'YouTube URL or video id',
        border: OutlineInputBorder(),
      ),
      onSubmitted: (url) {
        if (YoutubePlayerController.convertUrlToId(url) case final id?) {
          context.ytController.loadVideoById(videoId: id);
        }
      },
    ),
  );
}

class const ListPage({super.key}) extends StatefulWidget {
  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final _controllers = [
    for (final id in _videos) YoutubePlayerController.fromVideoId(videoId: id),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      unawaited(controller.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tap to play')),
    body: ListView.separated(
      padding: const .all(16),
      itemCount: _controllers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: .circular(12),
        child: YoutubePlayerThumbnail(controller: _controllers[i]),
      ),
    ),
  );
}
