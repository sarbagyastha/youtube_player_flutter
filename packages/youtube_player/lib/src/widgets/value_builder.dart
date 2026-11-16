// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../controller.dart';
import '../value.dart';

/// Provides a [YoutubePlayerController] to descendants.
class const YoutubePlayerControllerProvider({
  super.key,

  /// The provided controller.
  required final YoutubePlayerController controller,
  required super.child,
}) extends InheritedWidget {
  /// The nearest provided controller.
  static YoutubePlayerController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'No YoutubePlayerControllerProvider found above this context.',
    );
    return controller!;
  }

  /// The nearest provided controller, if any.
  static YoutubePlayerController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<YoutubePlayerControllerProvider>()
      ?.controller;

  @override
  bool updateShouldNotify(YoutubePlayerControllerProvider oldWidget) =>
      oldWidget.controller != controller;
}

/// Shorthand for [YoutubePlayerControllerProvider.of].
extension YoutubePlayerControllerExtension on BuildContext {
  /// The nearest provided [YoutubePlayerController].
  YoutubePlayerController get ytController =>
      YoutubePlayerControllerProvider.of(this);
}

/// Rebuilds when the player value changes. Uses the provided controller
/// when [controller] is null.
class const YoutubeValueBuilder({
  super.key,

  /// Builds the widget for the latest value.
  required final Widget Function(BuildContext context, YoutubePlayerValue value)
  builder,

  /// Rebuild only when this returns true (defaults to any change).
  final bool Function(YoutubePlayerValue previous, YoutubePlayerValue current)?
  buildWhen,

  /// The controller to listen to.
  final YoutubePlayerController? controller,
}) extends StatefulWidget {
  @override
  State<YoutubeValueBuilder> createState() => _YoutubeValueBuilderState();
}

class _YoutubeValueBuilderState extends State<YoutubeValueBuilder> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _subscription;
  late YoutubePlayerValue _value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bind(widget.controller ?? context.ytController);
  }

  @override
  void didUpdateWidget(YoutubeValueBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bind(widget.controller ?? context.ytController);
  }

  void _bind(YoutubePlayerController controller) {
    if (controller == _controller) return;
    _subscription?.cancel();
    _controller = controller;
    _value = controller.value;
    _subscription = controller.stream.listen((value) {
      final rebuild = widget.buildWhen?.call(_value, value) ?? true;
      _value = value;
      if (rebuild && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
