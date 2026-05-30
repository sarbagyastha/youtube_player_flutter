import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';
import '../../theme/youtube_player_theme.dart';

/// A button that opens a playback speed picker.
///
/// When [useIcon] is true, renders as a speed icon button.
/// When false, renders as a text chip showing the current rate.
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
      return YoutubeValueBuilder(
        controller: controller,
        buildWhen: (o, n) => o.playbackRate != n.playbackRate,
        builder: (context, value) {
          return IconButton(
            icon: Icon(Icons.speed_rounded, color: theme.controlsColor),
            onPressed: () {
              OverlayControllerScope.of(context).cancelTimer();
              _showSpeedSheet(context, value.playbackRate);
            },
          );
        },
      );
    }

    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.playbackRate != n.playbackRate,
      builder: (context, value) {
        final rate = value.playbackRate;
        final label =
            rate == rate.truncateToDouble() ? '${rate.toInt()}×' : '$rate×';

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
      builder: (_) => _SpeedPickerSheet(
        controller: controller,
        initialRate: currentRate,
      ),
    ).whenComplete(overlayCtrl.resetTimer);
  }
}

class _SpeedPickerSheet extends StatefulWidget {
  const _SpeedPickerSheet({
    required this.controller,
    required this.initialRate,
  });

  final YoutubePlayerController controller;
  final double initialRate;

  @override
  State<_SpeedPickerSheet> createState() => _SpeedPickerSheetState();
}

class _SpeedPickerSheetState extends State<_SpeedPickerSheet> {
  static const _presetSpeeds = <double>[0.25, 1.0, 1.25, 1.5, 2.0];

  late double _currentRate;

  @override
  void initState() {
    super.initState();
    _currentRate = _presetSpeeds.reduce(
      (a, b) =>
          (a - widget.initialRate).abs() < (b - widget.initialRate).abs()
              ? a
              : b,
    );
  }

  void _setRate(double rate) {
    setState(() => _currentRate = rate);
    widget.controller.setPlaybackRate(rate);
  }

  String get _rateLabel {
    if (_currentRate == 1.0) return '1x';
    if (_currentRate == _currentRate.truncateToDouble()) {
      return '${_currentRate.toInt()}x';
    }
    return '${_currentRate}x';
  }

  String _chipLabel(double speed) {
    if (speed == speed.truncateToDouble()) return '${speed.toInt()}x';
    return '${speed}x';
  }

  int get _currentIndex => _presetSpeeds.indexOf(_currentRate);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _rateLabel,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _CircleIconButton(
                  icon: Icons.remove,
                  onPressed: _currentIndex > 0
                      ? () => _setRate(_presetSpeeds[_currentIndex - 1])
                      : null,
                ),
                Expanded(
                  child: Slider(
                    value: _currentIndex.toDouble(),
                    min: 0,
                    max: (_presetSpeeds.length - 1).toDouble(),
                    divisions: _presetSpeeds.length - 1,
                    onChanged: (v) => _setRate(_presetSpeeds[v.round()]),
                  ),
                ),
                _CircleIconButton(
                  icon: Icons.add,
                  onPressed: _currentIndex < _presetSpeeds.length - 1
                      ? () => _setRate(_presetSpeeds[_currentIndex + 1])
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _presetSpeeds.map((speed) {
                final selected = speed == _currentRate;
                return GestureDetector(
                  onTap: () => _setRate(speed),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _chipLabel(speed),
                          style: TextStyle(
                            color: selected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        speed == 1.0 ? 'Normal' : 'Normal',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: speed == 1.0
                                  ? (selected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant)
                                  : Colors.transparent,
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }
}
