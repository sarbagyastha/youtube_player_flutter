// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/youtube_player_controller.dart';
import '../helpers/youtube_value_provider.dart';
import 'youtube_player.dart';

/// A widget that scaffolds the [YoutubePlayer] and handles fullscreen functionality.
///
/// **Deprecated.** [YoutubePlayer] now manages fullscreen internally via
/// [OverlayPortal] — no scaffold wrapper is required.
///
/// ## Migration
///
/// Before:
/// ```dart
/// YoutubePlayerScaffold(
///   controller: _controller,
///   builder: (context, player) {
///     return Scaffold(
///       body: Column(
///         children: [player, const Controls()],
///       ),
///     );
///   },
/// )
/// ```
///
/// After:
/// ```dart
/// // Wrap with YoutubePlayerControllerProvider only if descendant widgets
/// // access the controller via context.ytController.
/// YoutubePlayerControllerProvider(
///   controller: _controller,
///   child: Scaffold(
///     body: Column(
///       children: [
///         YoutubePlayer(controller: _controller),
///         const Controls(),
///       ],
///     ),
///   ),
/// )
/// ```
@Deprecated(
  'YoutubePlayerScaffold is no longer required. '
  'YoutubePlayer now handles fullscreen internally via OverlayPortal — '
  'no SystemChrome calls, no scaffold wrapper needed.\n\n'
  'Migration:\n\n'
  '  // Before\n'
  '  YoutubePlayerScaffold(\n'
  '    controller: _controller,\n'
  '    builder: (context, player) => Scaffold(body: player),\n'
  '  )\n\n'
  '  // After\n'
  '  YoutubePlayerControllerProvider(\n'
  '    controller: _controller,\n'
  '    child: Scaffold(\n'
  '      body: YoutubePlayer(controller: _controller),\n'
  '    ),\n'
  '  )\n\n'
  'Omit YoutubePlayerControllerProvider if no descendant uses context.ytController.',
)
class YoutubePlayerScaffold extends StatelessWidget {
  /// Creates [YoutubePlayerScaffold].
  @Deprecated(
    'YoutubePlayerScaffold is no longer required. '
    'YoutubePlayer now handles fullscreen internally via OverlayPortal — '
    'no SystemChrome calls, no scaffold wrapper needed.\n\n'
    'Migration:\n\n'
    '  // Before\n'
    '  YoutubePlayerScaffold(\n'
    '    controller: _controller,\n'
    '    builder: (context, player) => Scaffold(body: player),\n'
    '  )\n\n'
    '  // After\n'
    '  YoutubePlayerControllerProvider(\n'
    '    controller: _controller,\n'
    '    child: Scaffold(\n'
    '      body: YoutubePlayer(controller: _controller),\n'
    '    ),\n'
    '  )\n\n'
    'Omit YoutubePlayerControllerProvider if no descendant uses context.ytController.',
  )
  const YoutubePlayerScaffold({
    super.key,
    required this.builder,
    required this.controller,
    this.aspectRatio = 16 / 9,
    this.autoFullScreen = true,
    this.defaultOrientations = DeviceOrientation.values,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.fullscreenOrientations = const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    this.lockedOrientations = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    this.enableFullScreenOnVerticalDrag = true,
    this.backgroundColor,
    @Deprecated('Unused parameter. Use `YoutubePlayerParam.userAgent` instead.')
    this.userAgent,
  });

  /// Builds the child widget. The [player] argument is the [YoutubePlayer].
  final Widget Function(BuildContext context, Widget player) builder;

  /// The player controller.
  final YoutubePlayerController controller;

  /// The aspect ratio of the player. Ignored in fullscreen.
  final double aspectRatio;

  /// Whether the player should enter fullscreen on device orientation changes.
  ///
  /// Passed through to [YoutubePlayer.autoFullScreen].
  final bool autoFullScreen;

  /// Unused. Orientation is no longer controlled via [SystemChrome].
  final List<DeviceOrientation> defaultOrientations;

  /// Unused. Orientation is no longer controlled via [SystemChrome].
  final List<DeviceOrientation> fullscreenOrientations;

  /// Unused. Orientation is no longer controlled via [SystemChrome].
  final List<DeviceOrientation> lockedOrientations;

  /// Enables switching full screen mode on vertical drag in the player.
  final bool enableFullScreenOnVerticalDrag;

  /// Which gestures should be consumed by the youtube player.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// The background color of the WebView.
  final Color? backgroundColor;

  /// Unused. Use `YoutubePlayerParam.userAgent` instead.
  final String? userAgent;

  @override
  Widget build(BuildContext context) {
    final player = YoutubePlayer(
      controller: controller,
      aspectRatio: aspectRatio,
      gestureRecognizers: gestureRecognizers,
      enableFullScreenOnVerticalDrag: enableFullScreenOnVerticalDrag,
      backgroundColor: backgroundColor,
      autoFullScreen: autoFullScreen,
    );

    return YoutubePlayerControllerProvider(
      controller: controller,
      child: builder(context, player),
    );
  }
}
