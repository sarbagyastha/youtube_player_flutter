import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

void main() => runApp(const ExampleApp());

const _videos = [
  'tcodrIK2P_I',
  'H5v3kku4y6Q',
  'nPt8bK2gbaU',
  'K18cpp_-gP8',
  'iLnmTe5Q2Qw',
  '_WoCV4c6XOE',
  'KmzdUe0RSJo',
  '6jZDSSZZxjQ',
  'p2lYr3vM_1w',
  '7QUtEmBT_-w',
  '34_PXCzGw1M',
];

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
            tooltip: 'Custom controls',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CustomControlsPage(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Player elements',
            icon: const Icon(Icons.visibility),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ElementsPage()),
            ),
          ),
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
          // Buffering counts as playing, so the button doesn't flicker.
          IconButton.filled(
            tooltip: value.playerState.isActive ? 'Pause' : 'Play',
            icon: Icon(
              value.playerState.isActive ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: value.playerState.isActive
                ? controller.pauseVideo
                : controller.playVideo,
          ),
          IconButton(
            tooltip: 'Next',
            icon: const Icon(Icons.skip_next),
            onPressed: controller.nextVideo,
          ),
          IconButton(
            tooltip: value.isMuted ? 'Unmute' : 'Mute',
            icon: Icon(value.isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: value.isMuted ? controller.unMute : controller.mute,
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
      controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Players in a list')),
    body: ListView.separated(
      padding: const .all(16),
      itemCount: _controllers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: .circular(12),
        child: YoutubePlayer(controller: _controllers[i], keepAlive: true),
      ),
    ),
  );
}

class const CustomControlsPage({super.key}) extends StatefulWidget {
  @override
  State<CustomControlsPage> createState() => _CustomControlsPageState();
}

class _CustomControlsPageState extends State<CustomControlsPage> {
  final _controller = YoutubePlayerController.fromVideoId(videoId: _videos[2]);

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Custom controls')),
    body: ListView(
      children: [
        // No params needed: controlsBuilder turns YouTube's controls off.
        YoutubePlayer(
          controller: _controller,
          controlsBuilder: (context, value) => _Overlay(value),
        ),
      ],
    ),
  );
}

class const _Overlay(final YoutubePlayerValue value) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    final playing = value.playerState.isActive;
    return GestureDetector(
      behavior: .opaque,
      onTap: playing ? controller.pauseVideo : controller.playVideo,
      child: Stack(
        children: [
          Center(
            child: AnimatedOpacity(
              opacity: playing ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x99000000),
                  shape: .circle,
                ),
                child: Padding(
                  padding: .all(12),
                  child: Icon(Icons.play_arrow, size: 48, color: Colors.white),
                ),
              ),
            ),
          ),
          Align(
            alignment: .bottomCenter,
            child: StreamBuilder<YoutubeVideoState>(
              stream: controller.videoStateStream,
              initialData: const YoutubeVideoState(),
              builder: (context, snapshot) {
                final duration = value.metaData.duration.inMilliseconds;
                final position = snapshot.requireData.position.inMilliseconds;
                return LinearProgressIndicator(
                  value: duration == 0 ? 0 : (position / duration).clamp(0, 1),
                  minHeight: 4,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Hides YouTube's own UI elements and decides what clicks on them do.
class const ElementsPage({super.key}) extends StatefulWidget {
  @override
  State<ElementsPage> createState() => _ElementsPageState();
}

class _ElementsPageState extends State<ElementsPage> {
  /// Elements whose clicks are blocked.
  final _blocked = <PlayerElement>{
    PlayerElement.youtubeLogo,
    PlayerElement.channel,
  };

  late final _controller = YoutubePlayerController.fromVideoId(
    videoId: _videos[3],
    elementVisibility: (element) => element != PlayerElement.watchLaterButton,
    onNavigationRequest: (request) {
      final blocked = _blocked.contains(request.element);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${blocked ? 'Blocked' : 'Allowed'} ${request.element.name}'
              '${request.uri == null ? '' : ': ${request.uri}'}',
            ),
          ),
        );
      return blocked ? .prevent : .navigate;
    },
  );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Player elements')),
    body: ListView(
      children: [
        YoutubePlayer(controller: _controller),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Switch: shown or hidden. Chip: clicks blocked. '
            'Android, iOS and macOS only.',
          ),
        ),
        for (final element in PlayerElement.values)
          SwitchListTile(
            title: Text(element.name),
            secondary: FilterChip(
              label: const Text('Block'),
              selected: _blocked.contains(element),
              onSelected: (block) => setState(
                () => block ? _blocked.add(element) : _blocked.remove(element),
              ),
            ),
            value: _controller.isElementVisible(element),
            onChanged: (visible) =>
                setState(() => _controller.setElementVisible(element, visible)),
          ),
      ],
    ),
  );
}
