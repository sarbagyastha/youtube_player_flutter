import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../iframe_api/youtube_player_iframe_api.dart';
import 'youtube_player_event_handler.dart';

class YoutubePlayerController implements YoutubePlayerIFrameAPI {
  YoutubePlayerController() {
    _eventHandler = YoutubePlayerEventHandler(this);
    javaScriptChannels = _eventHandler.javascriptChannels;
  }

  final Completer<WebViewController> _webViewControllerCompleter = Completer();

  late final YoutubePlayerEventHandler _eventHandler;
  late final Set<JavascriptChannel> javaScriptChannels;

  Future<WebViewController> get webViewController {
    return _webViewControllerCompleter.future;
  }

  @override
  Future<void> cuePlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  }) {
    return _run(
      'cuePlaylist',
      data: {
        'list': list,
        'listType': listType?.value,
        'index': index,
        'startSeconds': startSeconds,
      },
    );
  }

  @override
  Future<void> cueVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  }) {
    return _run(
      'cueVideoById',
      data: {
        'videoId': videoId,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
      },
    );
  }

  @override
  Future<void> cueVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  }) {
    return _run(
      'cueVideoByUrl',
      data: {
        'mediaContentUrl': mediaContentUrl,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
      },
    );
  }

  @override
  Future<void> loadPlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  }) {
    return _run(
      'loadPlaylist',
      data: {
        'list': list,
        'listType': listType?.value,
        'index': index,
        'startSeconds': startSeconds,
      },
    );
  }

  @override
  Future<void> loadVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  }) {
    return _run(
      'loadVideoById',
      data: {
        'videoId': videoId,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
      },
    );
  }

  @override
  Future<void> loadVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  }) {
    return _run(
      'loadVideoByUrl',
      data: {
        'mediaContentUrl': mediaContentUrl,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
      },
    );
  }

  Future<void> load(
    WebViewController controller, {
    String? baseUrl,
  }) async {
    _webViewControllerCompleter.complete(controller);
    final playerHtml = await rootBundle.loadString(
      'packages/youtube_player_iframe/assets/player.html',
    );

    await controller.loadHtmlString(
      playerHtml.replaceFirst('<<playerVars>>', "{'playsinline': 1}"),
      baseUrl: baseUrl,
    );
  }

  Future<void> _run(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    await _eventHandler.isReady;

    final controller = await _webViewControllerCompleter.future;
    final varArgs = data == null ? '' : jsonEncode(data);

    return controller.runJavascript('player.$functionName($varArgs);');
  }
}
