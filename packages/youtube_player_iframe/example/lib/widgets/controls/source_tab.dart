import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class SourceTab extends StatefulWidget {
  const SourceTab({super.key});

  @override
  State<SourceTab> createState() => _SourceTabState();
}

class _SourceTabState extends State<SourceTab> {
  late TextEditingController _textController;
  ListType? _playlistType;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source type selector
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Video / URL'),
                selected: _playlistType == null,
                onSelected: (_) => setState(() => _playlistType = null),
              ),
              ...ListType.values.map(
                (type) => ChoiceChip(
                  label: Text(type.value),
                  selected: _playlistType == type,
                  onSelected: (_) => setState(() => _playlistType = type),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Input field
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: _hint,
                helperText: _helperText,
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w300,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => _textController.clear(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Load / Cue buttons
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final id = _cleanId(_textController.text);
                    if (id != null) {
                      context.ytController.loadVideoById(videoId: id);
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: const Text('Load'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final id = _cleanId(_textController.text);
                    if (id != null) {
                      context.ytController.cueVideoById(videoId: id);
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: const Text('Cue'),
                ),
              ),
            ],
          ),

          if (_playlistType != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () {
                      context.ytController.loadPlaylist(
                        list: [_textController.text],
                        listType: _playlistType!,
                      );
                      FocusScope.of(context).unfocus();
                    },
                    child: const Text('Load Playlist'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.ytController.cuePlaylist(
                        list: [_textController.text],
                        listType: _playlistType!,
                      );
                      FocusScope.of(context).unfocus();
                    },
                    child: const Text('Cue Playlist'),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          _DeepLinkHint(videoIdController: _textController),
        ],
      ),
    );
  }

  String? get _helperText {
    return switch (_playlistType) {
      ListType.playlist => '"PLj0L3ZL0ijTdhFSueRKK-mLFAtDuvzdje"',
      ListType.userUploads => '"pewdiepie", "tseries"',
      _ => null,
    };
  }

  String get _hint {
    return switch (_playlistType) {
      ListType.playlist => 'Enter playlist id',
      ListType.userUploads => 'Enter channel name',
      _ => r'Enter youtube <video id> or <link>',
    };
  }

  String? _cleanId(String source) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return YoutubePlayerController.convertUrlToId(source);
    } else if (source.length == 11) {
      return source;
    } else {
      _showSnackBar('Invalid Source');
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class _DeepLinkHint extends StatelessWidget {
  const _DeepLinkHint({required this.videoIdController});

  final TextEditingController videoIdController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Deep link',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Open a specific video by navigating to:',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  r'/?v=<videoId>  or  /watch?v=<videoId>',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (videoIdController.text.length == 11)
                IconButton(
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Copy deep link',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    final uri = Uri.base.replace(
                      path: '/watch',
                      queryParameters: {'v': videoIdController.text},
                    );
                    Clipboard.setData(ClipboardData(text: uri.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Copied: $uri',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 14,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
