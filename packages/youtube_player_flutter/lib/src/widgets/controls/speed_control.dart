import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';
import '../../theme/youtube_player_theme.dart';

const _speeds = <double>[0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

/// A button that opens a bottom sheet speed picker.
///
/// When [useIcon] is true, renders as a settings gear icon button instead of a
/// text chip showing the current rate.
class SpeedControl extends StatelessWidget {
  const SpeedControl({
    super.key,
    required this.controller,
    this.useIcon = false,
  });

  final YoutubePlayerController controller;
  final bool useIcon;

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    if (useIcon) {
      return IconButton(
        icon: Icon(Icons.settings_rounded, color: theme.controlsColor),
        onPressed: () {
          OverlayControllerScope.of(context).cancelTimer();
          _showSpeedSheet(context, controller.value.playbackRate);
        },
      );
    }

    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.playbackRate != n.playbackRate,
      builder: (context, value) {
        final rate = value.playbackRate;
        final label = rate == rate.truncateToDouble()
            ? '${rate.toInt()}×'
            : '$rate×';

        return TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.controlsColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(40, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            OverlayControllerScope.of(context).cancelTimer();
            _showSpeedSheet(context, rate);
          },
          child: Text(label, style: const TextStyle(fontSize: 13)),
        );
      },
    );
  }

  void _showSpeedSheet(BuildContext context, double currentRate) {
    final overlayCtrl = OverlayControllerScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Playback speed',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _speeds.map((speed) {
                    final selected = speed == currentRate;
                    final speedLabel = speed == speed.truncateToDouble()
                        ? '${speed.toInt()}×'
                        : '$speed×';
                    return ChoiceChip(
                      label: Text(speedLabel),
                      selected: selected,
                      onSelected: (_) {
                        controller.setPlaybackRate(speed);
                        Navigator.of(sheetContext).pop();
                        overlayCtrl.resetTimer();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(overlayCtrl.resetTimer);
  }
}
