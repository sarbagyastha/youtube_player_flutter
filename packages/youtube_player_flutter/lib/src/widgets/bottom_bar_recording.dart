import 'package:flutter/material.dart';

import '../../youtube_player_flutter.dart';

/// This widget is used for displaying progress bar on recordings (i.e. non-live videos)
class BottomBarRecording extends StatelessWidget {
  const BottomBarRecording(
      {super.key,
      this.bottomActions,
      required this.actionsPadding,
      required this.progressColors});

  /// {@template youtube_player_flutter.bottomActions}
  /// Adds custom bottom bar widgets.
  /// {@endtemplate}
  final List<Widget>? bottomActions;

  /// {@template youtube_player_flutter.actionsPadding}
  /// Defines padding for [topActions] and [bottomActions].
  ///
  /// Default is EdgeInsets.all(8.0).
  /// {@endtemplate}
  final EdgeInsetsGeometry actionsPadding;

  /// {@template youtube_player_flutter.progressColors}
  /// Overrides default colors of the progress bar, takes [ProgressColors].
  /// {@endtemplate}
  final ProgressBarColors progressColors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          bottomActions == null ? const EdgeInsets.all(0.0) : actionsPadding,
      child: Row(
        children: bottomActions ??
            [
              const SizedBox(width: 14.0),
              const CurrentPosition(),
              const SizedBox(width: 8.0),
              ProgressBar(
                isExpanded: true,
                colors: progressColors,
              ),
              const RemainingDuration(),
              const PlaybackSpeedButton(),
              const FullScreenButton(),
            ],
      ),
    );
  }
}
