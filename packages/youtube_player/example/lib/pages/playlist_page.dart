import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/videos.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/section_card.dart';
import '../widgets/seek_bar.dart';
import '../widgets/transport_controls.dart';
import '../widgets/video_header.dart';
import '../widgets/video_thumbnail.dart';

/// Playlists from video ids or a YouTube playlist id, with a queue, loop and
/// shuffle.
class const PlaylistPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Playlists',
    create: () => YoutubePlayerController()..cuePlaylist(list: videoIds),
    children: const [
      VideoHeader(),
      SectionCard(
        title: 'Playback',
        icon: Icons.smart_display_outlined,
        child: Column(
          children: [SeekBar(), TransportControls(), _LoopShuffle()],
        ),
      ),
      SectionCard(
        title: 'Source',
        icon: Icons.source_outlined,
        child: _SourcePicker(),
      ),
      SectionCard(
        title: 'Queue',
        icon: Icons.queue_music,
        note: 'playlist and playlistIndex, refreshed as videos change.',
        child: _Queue(),
      ),
    ],
  );
}

class const _LoopShuffle() extends StatefulWidget {
  @override
  State<_LoopShuffle> createState() => _LoopShuffleState();
}

class _LoopShuffleState extends State<_LoopShuffle> {
  var _loop = false;
  var _shuffle = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    return Padding(
      padding: const .only(top: 8),
      child: Wrap(
        alignment: .center,
        spacing: 8,
        children: [
          FilterChip(
            avatar: const Icon(Icons.repeat),
            label: const Text('Loop'),
            selected: _loop,
            onSelected: (on) {
              setState(() => _loop = on);
              controller.setLoop(loopPlaylists: on);
            },
          ),
          FilterChip(
            avatar: const Icon(Icons.shuffle),
            label: const Text('Shuffle'),
            selected: _shuffle,
            onSelected: (on) {
              setState(() => _shuffle = on);
              controller.setShuffle(shufflePlaylists: on);
            },
          ),
        ],
      ),
    );
  }
}

enum _Source { ids, playlist }

class const _SourcePicker() extends StatefulWidget {
  @override
  State<_SourcePicker> createState() => _SourcePickerState();
}

class _SourcePickerState extends State<_SourcePicker> {
  var _source = _Source.ids;
  final _playlistId = TextEditingController(text: playlistId);

  @override
  void dispose() {
    _playlistId.dispose();
    super.dispose();
  }

  void _load() {
    final controller = context.ytController;
    switch (_source) {
      case .ids:
        controller.loadPlaylist(list: videoIds);
      case .playlist:
        final id = _playlistId.text.trim();
        if (id.isEmpty) return;
        controller.loadPlaylist(list: [id], listType: .playlist);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      SegmentedButton<_Source>(
        segments: const [
          ButtonSegment(
            value: .ids,
            icon: Icon(Icons.format_list_numbered),
            label: Text('Video ids'),
          ),
          ButtonSegment(
            value: .playlist,
            icon: Icon(Icons.playlist_play),
            label: Text('Playlist id'),
          ),
        ],
        selected: {_source},
        onSelectionChanged: (s) => setState(() => _source = s.single),
      ),
      const SizedBox(height: 12),
      if (_source == .playlist) ...[
        TextField(
          controller: _playlistId,
          decoration: const InputDecoration(
            labelText: 'Playlist id',
            helperText: 'Default: Flutter Widget of the Week',
            prefixIcon: Icon(Icons.tag),
          ),
        ),
        const SizedBox(height: 12),
      ] else
        Padding(
          padding: const .only(bottom: 12),
          child: Text(
            '${videoIds.length} videos passed as a list of ids.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      FilledButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Load playlist'),
      ),
    ],
  );
}

class const _Queue() extends StatefulWidget {
  @override
  State<_Queue> createState() => _QueueState();
}

class _QueueState extends State<_Queue> {
  List<String> _ids = const [];
  var _index = -1;
  StreamSubscription<YoutubePlayerValue>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.ytController;
    _subscription?.cancel();
    var previous = controller.value;
    _subscription = controller.stream.listen((value) {
      if (value.metaData.videoId != previous.metaData.videoId ||
          value.isReady != previous.isReady ||
          (value.playerState != previous.playerState &&
              value.playerState == .cued)) {
        _refresh();
      }
      previous = value;
    });
    _refresh();
  }

  Future<void> _refresh() async {
    final controller = context.ytController;
    final (ids, index) = await (
      controller.playlist,
      controller.playlistIndex,
    ).wait;
    if (mounted) {
      setState(() {
        _ids = ids;
        _index = index;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    final theme = Theme.of(context);
    if (_ids.isEmpty) {
      return const Padding(
        padding: .symmetric(vertical: 16),
        child: Center(child: Text('Queue is empty')),
      );
    }
    return Column(
      children: [
        Align(
          alignment: .centerLeft,
          child: Text(
            '${_index + 1} of ${_ids.length}',
            style: theme.textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        for (final (i, id) in _ids.indexed)
          Material(
            color: i == _index
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: .circular(12),
            child: InkWell(
              borderRadius: .circular(12),
              onTap: () => controller.playVideoAt(i),
              child: Padding(
                padding: const .all(6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: i == _index
                          ? Icon(
                              Icons.equalizer,
                              size: 18,
                              color: theme.colorScheme.primary,
                            )
                          : Text('${i + 1}', textAlign: .center),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 96, child: VideoThumbnail(id, radius: 8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        id,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: i == _index ? .w700 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
