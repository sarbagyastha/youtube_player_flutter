import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Player Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, brightness: .dark),
      home: const PlayerPage(),
    );
  }
}

const _videoIds = [
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

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late YoutubePlayerController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _videoIds[_currentIndex],
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: false,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _loadVideo(int index) {
    setState(() => _currentIndex = index);
    _controller.loadVideoById(videoId: _videoIds[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Player Flutter'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showThemeDemo,
            tooltip: 'Theme demo',
          ),
        ],
      ),
      body: ListView(
        children: [
          YoutubePlayer(controller: _controller),
          const SizedBox(height: 32),
          SizedBox(
            height: 90,
            child: CarouselView(
              itemExtent: 180,
              shrinkExtent: 100,
              itemSnapping: false,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onTap: _loadVideo,
              children: List.generate(_videoIds.length, (i) {
                return _ThumbnailCard(
                  videoId: _videoIds[i],
                  selected: i == _currentIndex,
                );
              }),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(height: 0),
          const SizedBox(height: 16),

          // Custom controls demo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Custom Controls',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: .center,
            ),
          ),
          const SizedBox(height: 8),
          _CustomBuilderDemo(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showThemeDemo() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ThemeDemoPage()));
  }
}

class _ThumbnailCard extends StatelessWidget {
  const _ThumbnailCard({required this.videoId, required this.selected});

  final String videoId;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(30);

    return Material(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: .antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            YoutubePlayerController.getThumbnail(
              videoId: videoId,
              quality: .high,
            ),
            fit: BoxFit.fitWidth,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Colors.black12,
              child: Icon(Icons.ondemand_video, color: Colors.white54),
            ),
          ),
          if (selected) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 3),
                borderRadius: borderRadius,
                color: colorScheme.primary.withValues(alpha: 0.4),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: colorScheme.onPrimary,
                  size: 36,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Demonstrates the [YoutubePlayerBuilder] callback for fully custom controls.
class _CustomBuilderDemo extends StatefulWidget {
  @override
  State<_CustomBuilderDemo> createState() => _CustomBuilderDemoState();
}

class _CustomBuilderDemoState extends State<_CustomBuilderDemo> {
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
      // Custom builder replaces the entire default controls overlay.
      // Use Stack to overlay controls on top of the player surface.
      builder: (context, player, ctrl) => Stack(
        children: [
          AbsorbPointer(child: player),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _MinimalControls(controller: ctrl),
          ),
        ],
      ),
    );
  }
}

/// A minimal custom controls bar — the simplest possible builder output.
class _MinimalControls extends StatelessWidget {
  const _MinimalControls({required this.controller});

  final YoutubePlayerController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            'Custom controls',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const Spacer(),
          YoutubeValueBuilder(
            controller: controller,
            buildWhen: (o, n) => o.playerState != n.playerState,
            builder: (context, value) {
              final isPlaying = value.playerState == PlayerState.playing;
              return IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: cs.primary,
                ),
                onPressed: isPlaying
                    ? controller.pauseVideo
                    : controller.playVideo,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.stop_rounded, color: cs.onSurfaceVariant),
            onPressed: controller.stopVideo,
          ),
        ],
      ),
    );
  }
}

/// Demonstrates [YoutubePlayerTheme] overriding the progress bar color.
class ThemeDemoPage extends StatefulWidget {
  const ThemeDemoPage({super.key});

  @override
  State<ThemeDemoPage> createState() => _ThemeDemoPageState();
}

class _ThemeDemoPageState extends State<ThemeDemoPage> {
  late final YoutubePlayerController _controller;
  Color _accentColor = Colors.red;

  static const _colorOptions = [
    (label: 'Red', color: Colors.red),
    (label: 'Green', color: Colors.green),
    (label: 'Blue', color: Colors.blue),
    (label: 'Amber', color: Colors.amber),
  ];

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: 'M7FIvfx5J10',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Demo')),
      body: ListView(
        children: [
          // Wrap the player in a Theme with a YoutubePlayerTheme extension
          Theme(
            data: Theme.of(context).copyWith(
              extensions: [
                YoutubePlayerTheme(progressBarActiveColor: _accentColor),
              ],
            ),
            child: YoutubePlayer(controller: _controller),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Accent color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: _colorOptions.map((opt) {
                final selected = _accentColor == opt.color;
                return ChoiceChip(
                  label: Text(opt.label),
                  selected: selected,
                  selectedColor: opt.color,
                  onSelected: (_) => setState(() => _accentColor = opt.color),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
