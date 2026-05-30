import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';
import '../../theme/youtube_player_theme.dart';

/// A button that opens a speed picker or settings sheet.
///
/// When [useIcon] is true, renders as a settings gear icon that opens a
/// YouTube-style settings sheet (Quality, Playback speed, Captions, etc.).
/// When false, renders as a text chip showing the current rate that opens the
/// speed picker directly.
class SpeedControl extends StatelessWidget {
  const SpeedControl({
    super.key,
    required this.controller,
    this.useIcon = false,
  });

  final YoutubePlayerController controller;
  final bool useIcon;

  String _speedLabel(double rate) {
    if (rate == 1.0) return 'Normal';
    return rate == rate.truncateToDouble() ? '${rate.toInt()}×' : '$rate×';
  }

  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    if (useIcon) {
      return IconButton(
        icon: Icon(Icons.settings_rounded, color: theme.controlsColor),
        onPressed: () {
          OverlayControllerScope.of(context).cancelTimer();
          _showSettingsSheet(context);
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

  void _showSettingsSheet(BuildContext context) {
    final overlayCtrl = OverlayControllerScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final rate = controller.value.playbackRate;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingsTile(
                icon: Icons.tune_rounded,
                title: 'Quality',
                value: 'Auto',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              _SettingsTile(
                icon: Icons.speed_rounded,
                title: 'Playback speed',
                value: _speedLabel(rate),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  overlayCtrl.cancelTimer();
                  _showSpeedSheet(context, rate);
                },
              ),
              _SettingsTile(
                icon: Icons.closed_caption_rounded,
                title: 'Captions',
                value: 'Off',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).whenComplete(overlayCtrl.resetTimer);
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget? trailing;
    if (value != null) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
        ],
      );
    }

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
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
