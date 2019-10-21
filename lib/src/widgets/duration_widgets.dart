import 'package:flutter/material.dart';

import '../player/youtube_player.dart';
import '../utils/duration_formatter.dart';

/// A widget which displays the current position of the video.
class CurrentPosition extends StatefulWidget {
  @override
  _CurrentPositionState createState() => _CurrentPositionState();
}

class _CurrentPositionState extends State<CurrentPosition> {
  @override
  Widget build(BuildContext context) {
    return Text(
      durationFormatter(
        YoutubePlayerController.of(context).value.position?.inMilliseconds ?? 0,
      ),
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.0,
      ),
    );
  }
}

/// A widget which displays the remaining duration of the video.
class RemainingDuration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    YoutubePlayerController controller = YoutubePlayerController.of(context);
    return Text(
      "- ${durationFormatter(
        (controller.value.duration?.inMilliseconds ?? 0) -
            (controller.value.position?.inMilliseconds ?? 0),
      )}",
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.0,
      ),
    );
  }
}
