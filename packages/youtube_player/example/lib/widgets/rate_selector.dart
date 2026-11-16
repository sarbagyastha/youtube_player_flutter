import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../utils/format.dart';

/// Chips for the rates the current video supports
/// (`availablePlaybackRates`), falling back to [PlaybackRate.all].
class const RateSelector({super.key}) extends StatefulWidget {
  @override
  State<RateSelector> createState() => _RateSelectorState();
}

class _RateSelectorState extends State<RateSelector> {
  List<double> _rates = [...PlaybackRate.all.reversed];
  String? _loadedFor;

  Future<void> _load(YoutubePlayerController controller, String videoId) async {
    _loadedFor = videoId;
    final rates = await controller.availablePlaybackRates;
    if (mounted && rates.length > 1) setState(() => _rates = rates);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    return YoutubeValueBuilder(
      buildWhen: (a, b) =>
          a.playbackRate != b.playbackRate ||
          a.isReady != b.isReady ||
          a.metaData.videoId != b.metaData.videoId,
      builder: (context, value) {
        final videoId = value.metaData.videoId;
        if (value.isReady && videoId.isNotEmpty && videoId != _loadedFor) {
          _load(controller, videoId);
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final rate in _rates)
              ChoiceChip(
                label: Text(formatRate(rate)),
                selected: rate == value.playbackRate,
                onSelected: (_) => controller.setPlaybackRate(rate),
              ),
          ],
        );
      },
    );
  }
}
