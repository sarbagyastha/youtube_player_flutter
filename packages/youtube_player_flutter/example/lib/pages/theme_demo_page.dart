import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
              children: [
                for (final opt in _colorOptions)
                  ChoiceChip(
                    label: Text(opt.label),
                    selected: _accentColor == opt.color,
                    selectedColor: opt.color,
                    onSelected: (_) => setState(() => _accentColor = opt.color),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
