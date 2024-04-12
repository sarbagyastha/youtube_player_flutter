// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'content_type.dart';
import 'http_request_factory.dart';

/// An implementation of [PlatformWebViewControllerCreationParams] using Flutter
/// for Web API.
@immutable
class WebYoutubePlayerIframeControllerCreationParams
    extends PlatformWebViewControllerCreationParams {
  /// Creates a new [WebYoutubePlayerIframeControllerCreationParams] instance.
  WebYoutubePlayerIframeControllerCreationParams({
    this.httpRequestFactory = const HttpRequestFactory(),
  }) : super();

  /// Creates a [WebYoutubePlayerIframeControllerCreationParams] instance based on [PlatformWebViewControllerCreationParams].
  WebYoutubePlayerIframeControllerCreationParams.fromPlatformWebViewControllerCreationParams(
    // Recommended placeholder to prevent being broken by platform interface.
    // ignore: avoid_unused_constructor_parameters
    PlatformWebViewControllerCreationParams params, {
    HttpRequestFactory httpRequestFactory = const HttpRequestFactory(),
  }) : this(httpRequestFactory: httpRequestFactory);

  /// Handles creating and sending URL requests.
  final HttpRequestFactory httpRequestFactory;

  static int _nextIFrameId = 0;

  /// The underlying element used as the WebView.
  @visibleForTesting
  final YoutubeIframeElement ytiFrame =
      YoutubeIframeElement(id: _nextIFrameId++)..credentialless = true;
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

  JavaScriptChannelParams? _javaScriptChannelParams;

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) {
    _params.ytiFrame.srcdoc = html;
    return SynchronousFuture(null);
  }

  @override
  Future<void> runJavaScript(String javaScript) {
    _params.ytiFrame.runFunction(javaScript.replaceAll('"', '<<quote>>'));
    return SynchronousFuture(null);
  }

  @override
  Future<String> runJavaScriptReturningResult(String javaScript) async {
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    final function = javaScript.replaceAll('"', '<<quote>>');

    final completer = Completer<String>();
    final subscription = window.onMessage.listen(
      (event) {
        final data = jsonDecode(event.data.dartify() as String);

        if (data is Map && data.containsKey(key)) {
          completer.complete(data[key].toString());
        }
      },
    );

    _params.ytiFrame.runFunction(function, key: key);

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

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    if (!params.uri.hasScheme) {
      throw ArgumentError(
          'LoadRequestParams#uri is required to have a scheme.');
    }

    if (params.headers.isEmpty &&
        (params.body == null || params.body!.isEmpty) &&
        params.method == LoadRequestMethod.get) {
      _params.ytiFrame.src = params.uri.toString();
    } else {
      await _updateIFrameFromXhr(params);
    }
  }

  /// Performs an AJAX request defined by [params].
  Future<void> _updateIFrameFromXhr(LoadRequestParams params) async {
    final response = await _params.httpRequestFactory.request(
      params.uri,
      method: params.method,
      headers: params.headers,
      body: params.body,
    );

    final header = response.headers['content-type'] ?? 'text/html';
    final contentType = ContentType.parse(header);
    final encoding = Encoding.getByName(contentType.charset) ?? utf8;

    _params.ytiFrame.src = Uri.dataFromString(
      response.body,
      mimeType: contentType.mimeType,
      encoding: encoding,
    ).toString();
  }
}

/// An implementation of [PlatformWebViewWidget] using Flutter the for Web API.
class YoutubePlayerIframeWeb extends PlatformWebViewWidget {
  /// Constructs a [YoutubePlayerIframeWeb].
  YoutubePlayerIframeWeb(super.params)
      : _controller = params.controller as WebYoutubePlayerIframeController,
        super.implementation() {
    platformViewRegistry.registerViewFactory(
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

        if (channelParams != null) {
          window.onMessage.listen(
            (event) {
              if (channelParams.name == 'YoutubePlayer') {
                channelParams.onMessageReceived(
                  JavaScriptMessage(message: event.data.dartify() as String),
                );
              }
            },
          );
        }
      },
    );
  }
}

extension type YoutubeIframeElement._(HTMLIFrameElement element) {
  /// A class that represents a YouTube iframe element.
  YoutubeIframeElement({required int id})
      : element = HTMLIFrameElement()
          ..id = 'youtube-$id'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = 'none'
          ..allow = 'autoplay;fullscreen';

  /// The underlying [HTMLIFrameElement] used by the [YoutubeIframeElement].
  String get id => element.id;

  /// The URL of the page that the iframe will display.
  set src(String value) => element.src = value;

  /// The content of the page that the iframe will display.
  set srcdoc(String value) {
    element.srcdoc = value;

    // Fallback for browser that doesn't support srcdoc.
    element.src = Uri.dataFromString(
      value,
      mimeType: 'text/html',
      encoding: utf8,
    ).toString();
  }

  /// Provides a mechanism for developers to load third-party resources in [HTMLIFrameElement]s using a new, ephemeral context.
  /// This allows the third-party resources to be loaded without cookies, storage, or access to the parent frame.
  ///
  /// See more at:
  /// - [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/Security/IFrame_credentialless)
  /// - [Chrome Developers](https://developer.chrome.com/blog/anonymous-iframe-origin-trial)
  set credentialless(bool value) {
    element['credentialless'] = value.toJS;
  }

  /// Runs a function in the [HTMLIFrameElement] using postMessage.
  void runFunction(String function, {String? key}) {
    element.contentWindow?.postMessage(
      '{"key": "$key", "function": "$function"}'.toJS,
      '*'.toJS,
    );
  }
}
