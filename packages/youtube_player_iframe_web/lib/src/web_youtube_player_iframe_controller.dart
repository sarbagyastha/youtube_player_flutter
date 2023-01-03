// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'platform_view_stub.dart' if (dart.library.html) 'dart:ui' as ui;

/// An implementation of [PlatformWebViewControllerCreationParams] using Flutter
/// for Web API.
@immutable
class WebYoutubePlayerIframeControllerCreationParams
    extends PlatformWebViewControllerCreationParams {
  /// Creates a [WebYoutubePlayerIframeControllerCreationParams] instance based on [PlatformWebViewControllerCreationParams].
  WebYoutubePlayerIframeControllerCreationParams.fromPlatformWebViewControllerCreationParams(
    // Recommended placeholder to prevent being broken by platform interface.
    // ignore: avoid_unused_constructor_parameters
    PlatformWebViewControllerCreationParams params,
  );

  static int _nextIFrameId = 0;

  /// The underlying element used as the WebView.
  @visibleForTesting
  final IFrameElement ytiFrame = IFrameElement()
    ..id = 'youtube-${_nextIFrameId++}'
    ..width = '100%'
    ..height = '100%'
    ..style.border = 'none'
    ..allow = 'autoplay;fullscreen';
}

/// An implementation of [PlatformWebViewController] using Flutter for Web API.
class WebYoutubePlayerIframeController extends PlatformWebViewController {
  /// Constructs a [WebYoutubePlayerIframeController].
  WebYoutubePlayerIframeController(
    PlatformWebViewControllerCreationParams params,
  ) : super.implementation(
          params is WebYoutubePlayerIframeControllerCreationParams
              ? params
              : WebYoutubePlayerIframeControllerCreationParams
                  .fromPlatformWebViewControllerCreationParams(params),
        );

  WebYoutubePlayerIframeControllerCreationParams get _params {
    return params as WebYoutubePlayerIframeControllerCreationParams;
  }

  late final JavaScriptChannelParams _javaScriptChannelParams;

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) {
    _params.ytiFrame.srcdoc = html;

    // Fallback for browser that doesn't support srcdoc.
    _params.ytiFrame.src = Uri.dataFromString(
      html,
      mimeType: 'text/html',
      encoding: utf8,
    ).toString();

    return SynchronousFuture(null);
  }

  @override
  Future<void> runJavaScript(String javaScript) {
    final function = javaScript.replaceAll('"', '<<quote>>');
    _params.ytiFrame.contentWindow?.postMessage(
      '{"key": null, "function": "$function"}',
      '*',
    );

    return SynchronousFuture(null);
  }

  @override
  Future<String> runJavaScriptReturningResult(String javaScript) async {
    final contentWindow = _params.ytiFrame.contentWindow;
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    final function = javaScript.replaceAll('"', '<<quote>>');

    final completer = Completer<String>();
    final subscription = window.onMessage.listen(
      (event) {
        final data = jsonDecode(event.data);

        if (data is Map && data.containsKey(key)) {
          completer.complete(data[key].toString());
        }
      },
    );

    contentWindow?.postMessage(
      '{"key": "$key", "function": "$function"}',
      '*',
    );

    final result = await completer.future;
    subscription.cancel();

    return result;
  }

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {
    _javaScriptChannelParams = javaScriptChannelParams;
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    // no-op
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    // no-op
  }

  @override
  Future<void> setUserAgent(String? userAgent) async {
    // no-op
  }

  @override
  Future<void> enableZoom(bool enabled) async {
    // no-op
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    // no-op
  }
}

/// An implementation of [PlatformWebViewWidget] using Flutter the for Web API.
class YoutubePlayerIframeWeb extends PlatformWebViewWidget {
  /// Constructs a [YoutubePlayerIframeWeb].
  YoutubePlayerIframeWeb(PlatformWebViewWidgetCreationParams params)
      : _controller = params.controller as WebYoutubePlayerIframeController,
        super.implementation(params) {
    ui.platformViewRegistry.registerViewFactory(
      _controller._params.ytiFrame.id,
      (int viewId) => _controller._params.ytiFrame,
    );
  }

  final WebYoutubePlayerIframeController _controller;

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: params.key,
      viewType: (params.controller as WebYoutubePlayerIframeController)
          ._params
          .ytiFrame
          .id,
      onPlatformViewCreated: (_) {
        final channelParams = _controller._javaScriptChannelParams;
        window.onMessage.listen(
          (event) {
            if (channelParams.name == 'YoutubePlayer') {
              channelParams.onMessageReceived(
                JavaScriptMessage(message: event.data),
              );
            }
          },
        );
      },
    );
  }
}
