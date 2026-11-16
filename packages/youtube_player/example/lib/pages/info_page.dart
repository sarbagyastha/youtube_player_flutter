import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/videos.dart';
import '../utils/format.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/event_log.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_tile.dart';
import '../widgets/video_header.dart';

/// Status getters, async queries, caption options, errors and events.
class const InfoPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Info & events',
    create: () => YoutubePlayerController.fromVideoId(videoId: videoIds[1]),
    children: const [
      VideoHeader(),
      SectionCard(
        title: 'Live values',
        icon: Icons.monitor_heart_outlined,
        note: 'Synchronous getters, cached from player events.',
        child: _LiveValues(),
      ),
      SectionCard(
        title: 'Video data',
        icon: Icons.description_outlined,
        child: _VideoDataPanel(),
      ),
      SectionCard(
        title: 'Captions & modules',
        icon: Icons.closed_caption_outlined,
        note: 'Modules (e.g. captions) load once playback starts.',
        child: _CaptionsPanel(),
      ),
      SectionCard(
        title: 'Errors',
        icon: Icons.error_outline,
        note: 'Errors show in the header above.',
        child: _ErrorDemo(),
      ),
      SectionCard(
        title: 'Event log',
        icon: Icons.receipt_long_outlined,
        child: PlayerEventLog(),
      ),
    ],
  );
}

class const _LiveValues() extends StatefulWidget {
  @override
  State<_LiveValues> createState() => _LiveValuesState();
}

class _LiveValuesState extends State<_LiveValues> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ytController;
    return StatGrid(
      children: [
        StatTile(
          label: 'currentTime',
          value: formatDuration(secondsToDuration(c.currentTime)),
          icon: Icons.place_outlined,
        ),
        StatTile(
          label: 'duration',
          value: formatDuration(secondsToDuration(c.duration)),
          icon: Icons.schedule,
        ),
        StatTile(
          label: 'videoLoadedFraction',
          value: '${(c.videoLoadedFraction * 100).toStringAsFixed(0)} %',
          icon: Icons.downloading,
        ),
        StatTile(
          label: 'playerState',
          value: c.playerState.name,
          icon: Icons.toggle_on_outlined,
        ),
        StatTile(
          label: 'volume',
          value: '${c.volume}${c.isMuted ? ' (muted)' : ''}',
          icon: Icons.volume_down_outlined,
        ),
        StatTile(
          label: 'playbackRate',
          value: formatRate(c.playbackRate),
          icon: Icons.slow_motion_video,
        ),
      ],
    );
  }
}

class const _VideoDataPanel() extends StatefulWidget {
  @override
  State<_VideoDataPanel> createState() => _VideoDataPanelState();
}

class _VideoDataPanelState extends State<_VideoDataPanel> {
  String? _url;
  String? _embedCode;
  var _loading = false;

  Future<void> _fetch() async {
    final controller = context.ytController;
    setState(() => _loading = true);
    final (url, embedCode) = await (
      controller.videoUrl,
      controller.videoEmbedCode,
    ).wait;
    if (!mounted) return;
    setState(() {
      _url = url;
      _embedCode = embedCode;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    return YoutubeValueBuilder(
      buildWhen: (a, b) => a.metaData != b.metaData,
      builder: (context, value) {
        final data = controller.videoData;
        return Column(
          crossAxisAlignment: .stretch,
          children: [
            _Field('videoData.videoId', data.videoId),
            _Field('videoData.title', data.title),
            _Field('videoData.author', data.author),
            _Field(
              'metadata.duration',
              formatDuration(value.metaData.duration),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: .centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _loading ? null : _fetch,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: const Text('Fetch URL & embed code'),
              ),
            ),
            if (_url case final url?) _Field('videoUrl', url, copy: true),
            if (_embedCode case final code?)
              _Field('videoEmbedCode', code, copy: true),
          ],
        );
      },
    );
  }
}

class const _Field(
  final String label,
  final String value, {
  final bool copy = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const .symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value.isEmpty ? '—' : value,
                  maxLines: 4,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (copy)
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Copied $label')));
              },
            ),
        ],
      ),
    );
  }
}

class const _CaptionsPanel() extends StatefulWidget {
  @override
  State<_CaptionsPanel> createState() => _CaptionsPanelState();
}

class _CaptionsPanelState extends State<_CaptionsPanel> {
  List<String> _modules = const [];
  List<String> _captionOptions = const [];
  var _fontSize = 0;
  StreamSubscription<void>? _apiChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apiChanges?.cancel();
    // Modules load and unload as playback starts and stops.
    _apiChanges = context.ytController.apiChangeStream.listen((_) => _load());
  }

  @override
  void dispose() {
    _apiChanges?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final controller = context.ytController;
    final (modules, captions) = await (
      controller.getOptions(),
      controller.getOptions('captions'),
    ).wait;
    if (mounted) {
      setState(() {
        _modules = modules;
        _captionOptions = captions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'getOptions()',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (_modules.isEmpty) const Text('No modules loaded'),
            for (final m in _modules)
              Chip(
                label: Text(m),
                avatar: const Icon(Icons.extension, size: 16),
              ),
            for (final o in _captionOptions) Chip(label: Text('captions.$o')),
          ],
        ),
        const SizedBox(height: 16),
        Text('Caption font size', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: -1, label: Text('S')),
            ButtonSegment(value: 0, label: Text('M')),
            ButtonSegment(value: 1, label: Text('L')),
            ButtonSegment(value: 2, label: Text('XL')),
            ButtonSegment(value: 3, label: Text('XXL')),
          ],
          selected: {_fontSize},
          onSelectionChanged: (s) {
            setState(() => _fontSize = s.single);
            controller.setCaptionsFontSize(_fontSize);
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: .centerLeft,
          child: OutlinedButton.icon(
            onPressed: controller.reloadCaptions,
            icon: const Icon(Icons.subtitles_outlined),
            label: const Text('Reload captions'),
          ),
        ),
      ],
    );
  }
}

class const _ErrorDemo() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: () => controller.loadVideoById(videoId: missingVideoId),
          child: const Text('Missing video'),
        ),
        OutlinedButton(
          onPressed: () => controller.loadVideoById(videoId: invalidVideoId),
          child: const Text('Invalid id'),
        ),
        FilledButton.tonal(
          onPressed: () => controller.loadVideoById(videoId: videoIds[1]),
          child: const Text('Recover'),
        ),
      ],
    );
  }
}
