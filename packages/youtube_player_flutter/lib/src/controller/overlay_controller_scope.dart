// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'overlay_controller.dart';

/// Provides [OverlayController] to descendant control widgets without prop drilling.
class OverlayControllerScope extends InheritedWidget {
  const OverlayControllerScope({
    super.key,
    required this.overlayController,
    required super.child,
  });

  final OverlayController overlayController;

  static OverlayController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OverlayControllerScope>();
    assert(scope != null, 'No OverlayControllerScope found in context');
    return scope!.overlayController;
  }

  static OverlayController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<OverlayControllerScope>()
        ?.overlayController;
  }

  @override
  bool updateShouldNotify(OverlayControllerScope old) =>
      old.overlayController != overlayController;
}
