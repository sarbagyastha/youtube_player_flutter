// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../controller/youtube_player_controller.dart';
import '../player_value.dart';
import 'youtube_value_provider.dart';

/// Widget that builds itself based on the latest snapshot of interaction with a [YoutubePlayerController].
class YoutubeValueBuilder extends StatefulWidget {
  /// The [YoutubePlayerController].
  final YoutubePlayerController? controller;

  /// Build strategy fot the widget.
  final Widget Function(BuildContext, YoutubePlayerValue) builder;

  /// [buildWhen] will be invoked on each [controller] `value` change.
  /// [buildWhen] takes the previous `value` and current `state` and must
  /// return a [bool] which determines whether or not the [builder] function
  /// will be invoked.
  ///
  /// [buildWhen] is optional and if omitted, it will default to `true`.
  final bool Function(YoutubePlayerValue, YoutubePlayerValue)? buildWhen;

  /// Creates a new [YoutubeValueBuilder] that builds itself based on the latest
  /// snapshot of interaction with the specified [controller] and whose build
  /// strategy is given by [builder].
  ///
  /// The [controller] property can be omitted if [YoutubePlayerControllerProvider] is above this widget in widget tree.
  ///
  /// The [builder] must not be null.
  const YoutubeValueBuilder({
    super.key,
    required this.builder,
    this.buildWhen,
    this.controller,
  });

  @override
  State<YoutubeValueBuilder> createState() => _YoutubeValueBuilderState();
}

class _YoutubeValueBuilderState extends State<YoutubeValueBuilder> {
  StreamSubscription<YoutubePlayerValue>? _subscription;
  YoutubePlayerController? _controller;
  late YoutubePlayerValue _previousValue;
  late Widget _child;

  @override
  void didUpdateWidget(YoutubeValueBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = oldWidget.controller ?? context.ytController;
    final currentController = widget.controller ?? oldController;
    if (oldController != currentController) {
      if (_subscription != null) {
        _unsubscribe();
        _controller = currentController;
        _previousValue = _controller!.value;
      }
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = widget.controller ?? context.ytController;
    if (_controller == null) {
      _controller = controller;
      _previousValue = _controller!.value;
      _child = widget.builder(context, _previousValue);
      _subscribe();
    } else if (_controller != controller) {
      if (_subscription != null) {
        _unsubscribe();
        _controller = controller;
        _previousValue = _controller!.value;
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => _child;

  void _subscribe() {
    _subscription = _controller!.listen(
      (value) {
        if (widget.buildWhen?.call(_previousValue, value) ?? true) {
          if (!mounted) return;
          _child = widget.builder(context, value);
          setState(() {});
        }
        _previousValue = value;
      },
      onError: (e) => log(e.toString()),
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}
