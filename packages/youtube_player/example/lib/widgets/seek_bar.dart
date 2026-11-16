import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../utils/format.dart';

/// A seek slider with buffered progress and time labels.
///
/// Seeks without fetching while dragging, then with `allowSeekAhead` when the
/// drag ends, as the IFrame API recommends.
class const SeekBar({super.key}) extends StatefulWidget {
  /// Key of the seek [Slider], for tests.
  static const sliderKey = ValueKey('seek');

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  /// The dragged position, `0..1`, while the user drags.
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    final theme = Theme.of(context);
    return YoutubeValueBuilder(
      buildWhen: (a, b) => a.metaData.duration != b.metaData.duration,
      builder: (context, value) => StreamBuilder<YoutubeVideoState>(
        stream: controller.videoStateStream,
        initialData: YoutubeVideoState(
          position: secondsToDuration(controller.currentTime),
          loadedFraction: controller.videoLoadedFraction,
        ),
        builder: (context, snapshot) {
          final duration = value.metaData.duration;
          final total = duration.inMilliseconds;
          final state = snapshot.requireData;
          final played = total == 0
              ? 0.0
              : (state.position.inMilliseconds / total).clamp(0.0, 1.0);
          final fraction = _drag ?? played;
          double seconds(double v) => v * total / 1000;
          final labelStyle = theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFeatures: const [.tabularFigures()],
          );
          return Column(
            mainAxisSize: .min,
            children: [
              Slider(
                key: SeekBar.sliderKey,
                value: fraction,
                secondaryTrackValue: state.loadedFraction.clamp(0, 1),
                onChanged: total == 0
                    ? null
                    : (v) {
                        setState(() => _drag = v);
                        controller.seekTo(seconds: seconds(v));
                      },
                onChangeEnd: total == 0
                    ? null
                    : (v) {
                        controller.seekTo(
                          seconds: seconds(v),
                          allowSeekAhead: true,
                        );
                        setState(() => _drag = null);
                      },
              ),
              Padding(
                padding: const .symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      formatDuration(
                        Duration(milliseconds: (fraction * total).round()),
                      ),
                      style: labelStyle,
                    ),
                    const Spacer(),
                    Text(formatDuration(duration), style: labelStyle),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
