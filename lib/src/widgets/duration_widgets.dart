import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';
import '../utils/duration_formatter.dart';

/// A widget which displays the current position of the video.
class CurrentPosition extends StatefulWidget {
  @override
  _CurrentPositionState createState() => _CurrentPositionState();
}

class _CurrentPositionState extends State<CurrentPosition> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: YoutubePlayerController.of(context),
      builder: (context, value, _) {
        return Text(
          durationFormatter(
            value.position?.inMilliseconds ?? 0,
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.0,
          ),
        );
      },
    );
  }
}

/// A widget which displays the remaining duration of the video.
class RemainingDuration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: YoutubePlayerController.of(context),
      builder: (context, value, _) {
        return Text(
          "- ${durationFormatter(
            (value.duration?.inMilliseconds ?? 0) -
                (value.position?.inMilliseconds ?? 0),
          )}",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.0,
          ),
        );
      },
    );
  }
}
