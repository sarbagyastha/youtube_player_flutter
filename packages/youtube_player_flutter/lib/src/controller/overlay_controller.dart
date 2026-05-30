// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Controls the visibility of the player controls overlay with an auto-hide timer.
class OverlayController {
  OverlayController({
    this.autoHideDuration = const Duration(seconds: 3),
  });

  /// How long after the last interaction before controls auto-hide. Defaults to 3 seconds.
  final Duration autoHideDuration;

  /// Whether the controls overlay is currently visible.
  final isVisible = ValueNotifier<bool>(true);

  Timer? _timer;

  /// Show the controls and restart the auto-hide timer.
  void show() {
    isVisible.value = true;
    resetTimer();
  }

  /// Hide the controls and cancel the auto-hide timer.
  void hide() {
    _timer?.cancel();
    isVisible.value = false;
  }

  /// Toggle controls visibility.
  void toggle() => isVisible.value ? hide() : show();

  /// Restart the auto-hide countdown. Call on every control interaction.
  void resetTimer() {
    _timer?.cancel();
    _timer = Timer(autoHideDuration, hide);
  }

  /// Cancel auto-hide without hiding. Used when paused/buffering to keep controls visible.
  void cancelTimer() => _timer?.cancel();

  /// Dispose the timer and notifier.
  void dispose() {
    _timer?.cancel();
    isVisible.dispose();
  }
}
