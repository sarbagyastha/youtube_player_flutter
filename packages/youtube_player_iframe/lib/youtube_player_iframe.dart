// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as uri_launcher;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/src/controller/youtube_player_controller.dart';

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
    Key? key,
    this.controller,
    this.aspectRatio = 16 / 9,
    this.gestureRecognizers,
  }) : super(key: key);

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
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        allowsInlineMediaPlayback: true,
        initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
        onWebResourceError: print,
        onWebViewCreated: _controller.init,
        javascriptChannels: _controller.javaScriptChannels,
        zoomEnabled: false,
        gestureNavigationEnabled: false,
        navigationDelegate: (request) {
          final uri = Uri.tryParse(request.url);

          return _decideNavigation(uri);
        },
      ),
    );
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
