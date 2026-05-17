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

  @override
  bool updateShouldNotify(OverlayControllerScope old) =>
      old.overlayController != overlayController;
}
