// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/material.dart';

import '../controller.dart';
import '../player_value.dart';
import 'youtube_value_provider.dart';

/// Widget that builds itself based on the latest snapshot of interaction with a [YoutubePlayerController].
class YoutubeValueBuilder extends StatelessWidget {
  /// The [YoutubePlayerController].
  final YoutubePlayerController controller;

  /// Build strategy fot the widget.
  final Widget Function(BuildContext, YoutubePlayerValue) builder;

  /// Creates a new [YoutubeValueBuilder] that builds itself based on the latest
  /// snapshot of interaction with the specified [controller] and whose build
  /// strategy is given by [builder].
  ///
  /// The [controller] property can be omitted if [YoutubePlayerControllerProvider] is above this widget in widget tree.
  ///
  /// The [builder] must not be null.
  const YoutubeValueBuilder({
    Key key,
    this.controller,
    @required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ignore: close_sinks
    final _controller = controller ?? context.ytController;
    return StreamBuilder<YoutubePlayerValue>(
      stream: _controller,
      initialData: _controller.value,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return builder(context, snapshot.data);
        } else if (snapshot.hasError) {
          log(snapshot.error.toString());
        }
        return const SizedBox();
      },
    );
  }
}
