import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';

/// A widget to sound muted state change button.
class VolumeMutedButton extends StatefulWidget {
  /// Overrides the default [YoutubePlayerController].
  final YoutubePlayerController? controller;

  final bool muteFlag;

  /// Creates [VolumeMutedButton] widget.
  const VolumeMutedButton({
    this.controller,
    this.muteFlag = false,
  });

  @override
  _VolumeMutedButtonState createState() => _VolumeMutedButtonState();
}

class _VolumeMutedButtonState extends State<VolumeMutedButton> {
  late YoutubePlayerController _controller;
  late var muteFlag;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = YoutubePlayerController.of(context);
    if (controller == null) {
      assert(
        widget.controller != null,
        '\n\nNo controller could be found in the provided context.\n\n'
        'Try passing the controller explicitly.',
      );
      _controller = widget.controller!;
    } else {
      _controller = controller;
    }
  }

  @override
  void initState() {
    muteFlag = widget.muteFlag;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        muteFlag ? Icons.volume_off : Icons.volume_up,
        color: Colors.white,
        size: 24.0,
      ),
      onPressed: () {
        setState(() {
          if (muteFlag) {
            muteFlag = false;
            _controller.unMute();
          } else {
            muteFlag = true;
            _controller.mute();
          }
        });
      },
    );
    ;
  }
}
