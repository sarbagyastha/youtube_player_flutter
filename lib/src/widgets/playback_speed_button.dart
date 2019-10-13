import 'package:flutter/material.dart';

import '../../youtube_player_flutter.dart';

class PlaybackSpeedButton extends StatefulWidget {
  final Widget child;

  const PlaybackSpeedButton({this.child});

  @override
  _PlaybackSpeedButtonState createState() => _PlaybackSpeedButtonState();
}

class _PlaybackSpeedButtonState extends State<PlaybackSpeedButton> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PlaybackRate>(
      onSelected: YoutubePlayerController.of(context).setPlaybackRate,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.0, 8.0, 0.0, 8.0),
        child: widget.child ?? Image.asset(
          'assets/speedometer.webp',
          package: 'youtube_player_flutter',
          width: 20.0,
          height: 20.0,
          color: Colors.white,
        ),
      ),
      tooltip: 'PlayBack Rate',
      itemBuilder: (context) => [
        _popUpItem('2.0x', PlaybackRate.double),
        _popUpItem('1.75x', PlaybackRate.one_and_a_three_quarter),
        _popUpItem('1.5x', PlaybackRate.one_and_a_half),
        _popUpItem('1.25x', PlaybackRate.one_and_a_quarter),
        _popUpItem('Normal', PlaybackRate.normal),
        _popUpItem('0.75x', PlaybackRate.three_quarter),
        _popUpItem('0.5x', PlaybackRate.half),
        _popUpItem('0.25x', PlaybackRate.quarter),
      ],
    );
  }

  Widget _popUpItem(String text, PlaybackRate rate) {
    return CheckedPopupMenuItem(
      checked: YoutubePlayerController.of(context).value.playbackRate == rate,
      child: Text(text),
      value: rate,
    );
  }
}
