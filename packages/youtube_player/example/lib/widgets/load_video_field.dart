import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

/// Loads or cues a video from a YouTube URL or id, optionally clipped to a
/// start / end time.
class const LoadVideoField({
  super.key,
  final String hint = 'youtube.com/watch?v=… or a video id',
}) extends StatefulWidget {
  @override
  State<LoadVideoField> createState() => _LoadVideoFieldState();
}

class _LoadVideoFieldState extends State<LoadVideoField> {
  final _url = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  var _cue = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  void _submit() {
    final controller = context.ytController;
    final input = _url.text;
    final id = YoutubePlayerController.convertUrlToId(input);
    setState(() => _error = id == null ? 'Not a YouTube URL or id' : null);
    if (id == null) return;
    final start = double.tryParse(_start.text);
    final end = double.tryParse(_end.text);
    if (_cue) {
      controller.cueVideoById(
        videoId: id,
        startSeconds: start,
        endSeconds: end,
      );
    } else if (start == null && end == null) {
      // Accepts any URL form directly.
      controller.loadVideo(input);
    } else {
      controller.loadVideoById(
        videoId: id,
        startSeconds: start,
        endSeconds: end,
      );
    }
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      TextField(
        controller: _url,
        keyboardType: .url,
        textInputAction: .go,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _error,
          prefixIcon: const Icon(Icons.link),
          suffixIcon: IconButton(
            tooltip: _cue ? 'Cue' : 'Load',
            icon: const Icon(Icons.arrow_forward),
            onPressed: _submit,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _SecondsField(_start, 'Start (s)')),
          const SizedBox(width: 8),
          Expanded(child: _SecondsField(_end, 'End (s)')),
          const SizedBox(width: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Load')),
              ButtonSegment(value: true, label: Text('Cue')),
            ],
            selected: {_cue},
            onSelectionChanged: (s) => setState(() => _cue = s.single),
          ),
        ],
      ),
    ],
  );
}

class const _SecondsField(
  final TextEditingController controller,
  final String label,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: const .numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, isDense: true),
  );
}
