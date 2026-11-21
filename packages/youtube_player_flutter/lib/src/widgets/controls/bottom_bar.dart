// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../../controller/overlay_controller.dart';
import '../../controller/overlay_controller_scope.dart';
import '../../fullscreen/fullscreen.dart';
import '../../theme/youtube_player_theme.dart';
import '../../utils/duration_formatter.dart';
import 'fullscreen_button.dart';
import 'progress_bar.dart';

/// Bottom gradient bar: time pill + fullscreen button, then a thin seek slider.
class const BottomBar({
  super.key,
  required final YoutubePlayerController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = YoutubePlayerThemeResolver(context);

    return ValueListenableBuilder<bool>(
      valueListenable: YoutubeFullScreen.of(context, listen: false),
      builder: (context, isFullScreen, _) {
        // In fullscreen, use safe-area insets as a floor for horizontal padding
        // (max rather than add) so controls clear the notch without doubling
        // the existing spacing. Bottom inset is added for the home indicator.
        final EdgeInsets insets;
        if (isFullScreen) {
          final p = MediaQuery.paddingOf(context);
          insets = EdgeInsets.fromLTRB(
            math.max(12.0, p.left),
            0,
            math.max(4.0, p.right),
            p.bottom,
          );
        } else {
          insets = EdgeInsets.only(left: 16);
        }

        return Container(
          decoration: BoxDecoration(gradient: theme.bottomGradient),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(insets.left, 4, insets.right, 0),
                child: Row(
                  children: [
                    _TimePill(controller: controller, theme: theme),
                    const Spacer(),
                    const FullscreenButton(),
                  ],
                ),
              ),
              ProgressBar(
                controller: controller,
                leftPadding: insets.left,
                rightPadding: insets.right,
              ),
              SizedBox(height: insets.bottom),
            ],
          ),
        );
      },
    );
  }
}

/// Elapsed / total time. Rebuilds only when the displayed second changes,
/// and not at all while the controls overlay is hidden.
class _TimePill extends StatefulWidget {
  const _TimePill({required this.controller, required this.theme});

  final YoutubePlayerController controller;
  final YoutubePlayerThemeResolver theme;

  @override
  State<_TimePill> createState() => _TimePillState();
}

class _TimePillState extends State<_TimePill> {
  late final StreamSubscription<YoutubeVideoState> _subscription;
  OverlayController? _overlay;

  // Ticks only arrive while playing; start from the last known time.
  late int _seconds = widget.controller.currentTime.floor();
  late Duration _duration = widget.controller.metadata.duration;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.videoStateStream.listen(
      (state) => _update(state.position.inSeconds),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final overlay = OverlayControllerScope.maybeOf(context);
    if (overlay == _overlay) return;
    _overlay?.isVisible.removeListener(_onOverlayVisibility);
    _overlay = overlay?..isVisible.addListener(_onOverlayVisibility);
  }

  @override
  void dispose() {
    _overlay?.isVisible.removeListener(_onOverlayVisibility);
    _subscription.cancel();
    super.dispose();
  }

  void _onOverlayVisibility() => _update(widget.controller.currentTime.floor());

  void _update(int seconds) {
    if (!mounted || !(_overlay?.isVisible.value ?? true)) return;
    final duration = widget.controller.metadata.duration;
    if (seconds == _seconds && duration == _duration) return;
    setState(() {
      _seconds = seconds;
      _duration = duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Text(
        '${Duration(seconds: _seconds).toHhMmSs()} / '
        '${_duration.toHhMmSs()}',
        style: widget.theme.timerStyle,
      ),
    );
  }
}
