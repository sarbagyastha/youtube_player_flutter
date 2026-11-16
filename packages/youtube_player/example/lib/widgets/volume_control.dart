import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

/// A mute toggle and a volume slider (`setVolume`, `0..100`).
class const VolumeControl({super.key}) extends StatefulWidget {
  @override
  State<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    return YoutubeValueBuilder(
      buildWhen: (a, b) => a.isMuted != b.isMuted || a.volume != b.volume,
      builder: (context, value) {
        final volume = _drag ?? value.volume.toDouble();
        final muteButton = IconButton.filledTonal(
          tooltip: value.isMuted ? 'Unmute' : 'Mute',
          icon: Icon(value.isMuted ? Icons.volume_off : Icons.volume_up),
          onPressed: value.isMuted ? controller.unMute : controller.mute,
        );
        // e.g. iOS, where only the hardware buttons change media volume.
        if (!controller.supportsVolume) {
          return Row(
            spacing: 12,
            children: [
              muteButton,
              Text(
                'Use the device buttons to change the volume.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }
        return Row(
          children: [
            muteButton,
            Expanded(
              child: Slider(
                value: volume,
                max: 100,
                divisions: 20,
                label: '${volume.round()}',
                onChanged: (v) {
                  setState(() => _drag = v);
                  controller.setVolume(v.round());
                  if (value.isMuted && v > 0) controller.unMute();
                },
                onChangeEnd: (_) => setState(() => _drag = null),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${volume.round()}',
                textAlign: .end,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        );
      },
    );
  }
}
