import 'dart:async';

import 'package:flutter/foundation.dart';

/// Controls the visibility of the player controls overlay with an auto-hide timer.
class OverlayController {
  OverlayController({
    this.autoHideDuration = const Duration(seconds: 3),
  });

  final Duration autoHideDuration;
  final isVisible = ValueNotifier<bool>(true);
  Timer? _timer;

  void show() {
    isVisible.value = true;
    resetTimer();
  }

  void hide() {
    _timer?.cancel();
    isVisible.value = false;
  }

  void toggle() => isVisible.value ? hide() : show();

  /// Restart the auto-hide countdown. Call on every control interaction.
  void resetTimer() {
    _timer?.cancel();
    _timer = Timer(autoHideDuration, hide);
  }

  /// Cancel auto-hide without hiding. Used when paused/buffering to keep controls visible.
  void cancelTimer() => _timer?.cancel();

  void dispose() {
    _timer?.cancel();
    isVisible.dispose();
  }
}
