import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/src/player/youtube_player.dart';

import '../utils/duration_formatter.dart';

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

class TotalDuration extends StatelessWidget {
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
