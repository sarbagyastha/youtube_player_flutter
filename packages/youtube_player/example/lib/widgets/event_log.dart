import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

/// One line of a [LogView].
typedef LogEntry = ({DateTime time, String message});

/// A fixed-height, newest-first list of log entries.
class const LogView(
  final List<LogEntry> entries, {
  super.key,
  final double height = 220,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    String two(int n) => n.toString().padLeft(2, '0');
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: .circular(14),
      ),
      child: entries.isEmpty
          ? Center(child: Text('Nothing yet', style: mono))
          : ListView.builder(
              padding: const .all(12),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final (:time, :message) = entries[entries.length - 1 - i];
                return Padding(
                  padding: const .symmetric(vertical: 2),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${two(time.hour)}:${two(time.minute)}:'
                              '${two(time.second)}  ',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                        TextSpan(text: message),
                      ],
                    ),
                    style: mono,
                  ),
                );
              },
            ),
    );
  }
}

/// Logs what changes in the player value, plus `apiChangeStream` events.
class const PlayerEventLog({super.key}) extends StatefulWidget {
  @override
  State<PlayerEventLog> createState() => _PlayerEventLogState();
}

class _PlayerEventLogState extends State<PlayerEventLog> {
  final _entries = <LogEntry>[];
  final _subscriptions = <StreamSubscription<Object?>>[];
  YoutubePlayerController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.ytController;
    if (controller == _controller) return;
    _cancel();
    _controller = controller;
    var previous = controller.value;
    _subscriptions
      ..add(
        controller.stream.listen((value) {
          _describe(previous, value).forEach(_add);
          previous = value;
        }),
      )
      ..add(controller.apiChangeStream.listen((_) => _add('apiChange')));
  }

  Iterable<String> _describe(YoutubePlayerValue a, YoutubePlayerValue b) sync* {
    if (!a.isReady && b.isReady) yield 'ready';
    if (a.metaData.videoId != b.metaData.videoId) {
      yield 'video → ${b.metaData.videoId}';
    }
    if (a.playerState != b.playerState) yield 'state → ${b.playerState.name}';
    if (a.playbackRate != b.playbackRate) yield 'rate → ${b.playbackRate}';
    if (a.playbackQuality != b.playbackQuality) {
      yield 'quality → ${b.playbackQuality}';
    }
    if (a.isMuted != b.isMuted) yield b.isMuted ? 'muted' : 'unmuted';
    if (a.volume != b.volume) yield 'volume → ${b.volume}';
    if (a.isFullScreen != b.isFullScreen) {
      yield 'fullscreen → ${b.isFullScreen}';
    }
    if (a.error != b.error) yield 'error → ${b.error.name}';
    if (a.loadError != b.loadError && b.loadError != null) {
      yield 'loadError → ${b.loadError!.description}';
    }
    if (!a.isAutoplayBlocked && b.isAutoplayBlocked) yield 'autoplay blocked';
  }

  void _add(String message) {
    if (!mounted) return;
    setState(() {
      _entries.add((time: DateTime.now(), message: message));
      if (_entries.length > 100) _entries.removeAt(0);
    });
  }

  void _cancel() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LogView(_entries);
}
