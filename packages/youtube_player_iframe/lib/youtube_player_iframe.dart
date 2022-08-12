// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as uri_launcher;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/src/player_value.dart';

import 'youtube_player_iframe.dart';

export 'package:youtube_player_iframe/src/controller/youtube_player_controller.dart';
export 'package:youtube_player_iframe/src/iframe_api/youtube_player_iframe_api.dart';

export 'src/enums/playback_rate.dart';
export 'src/enums/player_state.dart';
export 'src/enums/thumbnail_quality.dart';
export 'src/enums/youtube_error.dart';
export 'src/helpers/youtube_value_builder.dart';
export 'src/helpers/youtube_value_provider.dart';
export 'src/meta_data.dart';
export 'src/player_params.dart';

/// A widget the scaffolds the [YoutubePlayerIFrame]so that it can be moved around easily in the view
/// and handles the fullscreen functionality.
class YoutubePlayerScaffold extends StatefulWidget {
  /// Creates [YoutubePlayerScaffold].
  const YoutubePlayerScaffold({
    super.key,
    required this.builder,
    required this.controller,
    this.aspectRatio = 16 / 9,
    this.autoFullScreen = true,
    this.defaultOrientations = DeviceOrientation.values,
    this.gestureRecognizers,
  });

  /// Builds the child widget.
  final Widget Function(BuildContext context, Widget player) builder;

  /// The player controller.
  final YoutubePlayerController controller;

  /// The aspect ratio of the player.
  ///
  /// The value is ignored on fullscreen mode.
  final double aspectRatio;

  /// Whether the player should be fullscreen on device orientation changes.
  final bool autoFullScreen;

  /// The default orientations for the device.
  final List<DeviceOrientation> defaultOrientations;

  /// Which gestures should be consumed by the youtube player.
  ///
  /// This property is ignored in web.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  State<YoutubePlayerScaffold> createState() => _YoutubePlayerScaffoldState();
}

class _YoutubePlayerScaffoldState extends State<YoutubePlayerScaffold> {
  late final GlobalObjectKey _playerKey;

  @override
  void initState() {
    super.initState();

    _playerKey = GlobalObjectKey(widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    final player = KeyedSubtree(
      key: _playerKey,
      child: YoutubePlayerIFrame(
        controller: widget.controller,
        aspectRatio: widget.aspectRatio,
        gestureRecognizers: widget.gestureRecognizers,
      ),
    );

    return YoutubePlayerControllerProvider(
      controller: widget.controller,
      child: kIsWeb
          ? widget.builder(context, player)
          : YoutubeValueBuilder(
              controller: widget.controller,
              buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
              builder: (context, value) {
                return _FullScreen(
                  auto: widget.autoFullScreen,
                  defaultOrientations: widget.defaultOrientations,
                  fullScreenOption: value.fullScreenOption,
                  child: Builder(
                    builder: (context) {
                      if (value.fullScreenOption.enabled) return player;

                      return widget.builder(context, player);
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _FullScreen extends StatefulWidget {
  const _FullScreen({
    required this.fullScreenOption,
    required this.defaultOrientations,
    required this.child,
    required this.auto,
  });

  final FullScreenOption fullScreenOption;
  final List<DeviceOrientation> defaultOrientations;
  final Widget child;
  final bool auto;

  @override
  State<_FullScreen> createState() => _FullScreenState();
}

class _FullScreenState extends State<_FullScreen> with WidgetsBindingObserver {
  Orientation? _previousOrientation;

  @override
  void initState() {
    super.initState();

    if (widget.auto) WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(_deviceOrientations);
    SystemChrome.setEnabledSystemUIMode(_uiMode);
  }

  @override
  void didUpdateWidget(_FullScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.fullScreenOption != widget.fullScreenOption) {
      SystemChrome.setPreferredOrientations(_deviceOrientations);
      SystemChrome.setEnabledSystemUIMode(_uiMode);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    final orientation = MediaQuery.of(context).orientation;
    final controller = YoutubePlayerControllerProvider.of(context);
    final isFullScreen = controller.value.fullScreenOption.enabled;

    if (_previousOrientation == orientation) return;

    if (!isFullScreen && orientation == Orientation.landscape) {
      controller.enterFullScreen(lock: false);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }

    _previousOrientation = orientation;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleFullScreenBackAction,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    if (widget.auto) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<DeviceOrientation> get _deviceOrientations {
    final fullscreen = widget.fullScreenOption;

    if (!fullscreen.enabled && fullscreen.locked) {
      return [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ];
    } else if (fullscreen.enabled) {
      return [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    }

    return widget.defaultOrientations;
  }

  SystemUiMode get _uiMode {
    return widget.fullScreenOption.enabled
        ? SystemUiMode.immersive
        : SystemUiMode.edgeToEdge;
  }

  Future<bool> _handleFullScreenBackAction() async {
    if (mounted && widget.fullScreenOption.enabled) {
      YoutubePlayerControllerProvider.of(context).exitFullScreen();
      return false;
    }

    return true;
  }
}

/// A widget to play or stream Youtube Videos.
class YoutubePlayerIFrame extends StatefulWidget {
  /// The [controller] for this player.
  final YoutubePlayerController? controller;

  /// Aspect ratio for the player.
  final double aspectRatio;

  /// Which gestures should be consumed by the youtube player.
  ///
  /// It is possible for other gesture recognizers to be competing with the player on pointer
  /// events, e.g if the player is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The player will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// By default vertical and horizontal gestures are absorbed by the player.
  /// Passing an empty set will ignore the defaults.
  ///
  /// This is ignored on web.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// A widget to play or stream Youtube Videos.
  const YoutubePlayerIFrame({
    super.key,
    this.controller,
    this.aspectRatio = 16 / 9,
    this.gestureRecognizers,
  });

  @override
  State<YoutubePlayerIFrame> createState() => _YoutubePlayerIFrameState();
}

class _YoutubePlayerIFrameState extends State<YoutubePlayerIFrame> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? YoutubePlayerController();
  }

  @override
  Widget build(BuildContext context) {
    Widget player = GestureDetector(
      onVerticalDragUpdate: _fullscreenGesture,
      child: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        allowsInlineMediaPlayback: true,
        initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
        onWebResourceError: print,
        onWebViewCreated: _controller.init,
        javascriptChannels: _controller.javaScriptChannels,
        zoomEnabled: false,
        gestureNavigationEnabled: false,
        gestureRecognizers: widget.gestureRecognizers,
        navigationDelegate: (request) {
          final uri = Uri.tryParse(request.url);
          return _decideNavigation(uri);
        },
      ),
    );

    if (_controller.params.showFullscreenButton) {
      player = Stack(
        children: [
          Positioned.fill(child: player),
          Positioned(
            bottom: 2,
            right: 16,
            width: 40,
            height: 40,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _controller.toggleFullScreen,
            ),
          ),
        ],
      );
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        return AspectRatio(
          aspectRatio: orientation == Orientation.landscape
              ? MediaQuery.of(context).size.aspectRatio
              : widget.aspectRatio,
          child: player,
        );
      },
    );
  }

  void _fullscreenGesture(DragUpdateDetails details) {
    final delta = details.delta.dy;

    if (delta.abs() > 10) {
      delta.isNegative
          ? _controller.enterFullScreen()
          : _controller.exitFullScreen();
    }
  }

  NavigationDecision _decideNavigation(Uri? uri) {
    if (uri == null) return NavigationDecision.prevent;

    final params = uri.queryParameters;
    final host = uri.host;
    final path = uri.path;

    String? featureName;
    if (host.contains('facebook') ||
        host.contains('twitter') ||
        host == 'youtu') {
      featureName = 'social';
    } else if (params.containsKey('feature')) {
      featureName = params['feature'];
    } else if (path == '/watch') {
      featureName = 'emb_info';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return NavigationDecision.navigate;
    }

    switch (featureName) {
      case 'emb_rel_pause':
      case 'emb_rel_end':
      case 'emb_info':
        final videoId = params['v'];
        if (videoId != null) _controller.loadVideoById(videoId: videoId);
        break;
      case 'emb_logo':
      case 'social':
      case 'wl_button':
        uri_launcher.launchUrl(uri);
        break;
    }

    return NavigationDecision.prevent;
  }
}
