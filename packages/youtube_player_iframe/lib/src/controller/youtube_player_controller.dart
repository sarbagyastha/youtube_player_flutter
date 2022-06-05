import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../player_value.dart';
import '../web_registrar/register_web_webview_stub.dart'
    if (dart.library.html) '../web_registrar/register_web_webview.dart';
import 'youtube_player_event_handler.dart';

class YoutubePlayerController implements YoutubePlayerIFrameAPI {
  YoutubePlayerController() {
    registerWebViewWebImplementation();
    _eventHandler = YoutubePlayerEventHandler(this);
    javaScriptChannels = _eventHandler.javascriptChannels;
  }

  final Completer<WebViewController> _webViewControllerCompleter = Completer();

  late final YoutubePlayerEventHandler _eventHandler;
  late final Set<JavascriptChannel> javaScriptChannels;

  final StreamController<YoutubePlayerValue> _valueController =
      StreamController.broadcast();
  YoutubePlayerValue _value = YoutubePlayerValue();

  /// The [YoutubePlayerValue].
  YoutubePlayerValue get value => _value;

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

  Future<void> init(WebViewController controller) async {
    await controller.runJavascript('var isWeb = $kIsWeb;');
    _webViewControllerCompleter.complete(controller);
    await load(params: const YoutubePlayerParams());
  }

  Future<void> load({
    required YoutubePlayerParams params,
    String? baseUrl,
  }) async {
    final playerHtml = await rootBundle.loadString(
      'packages/youtube_player_iframe/assets/player.html',
    );

    final controller = await _webViewControllerCompleter.future;
    await controller.loadHtmlString(
      playerHtml
          .replaceFirst('<<playerVars>>', params.toJson())
          .replaceFirst('<<isWeb>>', kIsWeb.toString()),
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

  /// MetaData for the currently loaded or cued video.
  YoutubeMetaData get metadata => _value.metaData;

  /// Creates new [YoutubePlayerValue] with assigned parameters and overrides
  /// the old one.
  void update({
    bool? isReady,
    bool? hasPlayed,
    Duration? position,
    double? buffered,
    bool? isFullScreen,
    int? volume,
    PlayerState? playerState,
    double? playbackRate,
    String? playbackQuality,
    YoutubeError? error,
    YoutubeMetaData? metaData,
  }) {
    final updatedValue = YoutubePlayerValue(
      isReady: isReady ?? value.isReady,
      hasPlayed: hasPlayed ?? value.hasPlayed,
      position: position ?? value.position,
      buffered: buffered ?? value.buffered,
      isFullScreen: isFullScreen ?? value.isFullScreen,
      volume: volume ?? value.volume,
      playerState: playerState ?? value.playerState,
      playbackRate: playbackRate ?? value.playbackRate,
      playbackQuality: playbackQuality ?? value.playbackQuality,
      error: error ?? value.error,
      metaData: metaData ?? value.metaData,
    );

    _valueController.add(updatedValue);
    _valueController.onListen = () {
      print(';o');
    };
  }

  /// Listen to updates in [YoutubePlayerController].
  StreamSubscription<YoutubePlayerValue> listen(
    void Function(YoutubePlayerValue event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _valueController.stream.listen(
      (value) {
        _value = value;
        onData?.call(value);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Converts fully qualified YouTube Url to video id.
  ///
  /// If videoId is passed as url then no conversion is done.
  static String? convertUrlToId(String url, {bool trimWhitespaces = true}) {
    if (!url.contains("http") && (url.length == 11)) return url;
    if (trimWhitespaces) url = url.trim();

    for (var regex in [
      r'^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$',
      r'^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$',
      r'^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$',
    ]) {
      Match? match = RegExp(regex).firstMatch(url);
      if (match != null && match.groupCount >= 1) return match.group(1);
    }

    return null;
  }

  /// Grabs YouTube video's thumbnail for provided video id.
  ///
  /// If [webp] is true, webp version of the thumbnail will be retrieved,
  /// Otherwise a JPG thumbnail.
  static String getThumbnail({
    required String videoId,
    String quality = ThumbnailQuality.standard,
    bool webp = true,
  }) {
    return webp
        ? 'https://i3.ytimg.com/vi_webp/$videoId/$quality.webp'
        : 'https://i3.ytimg.com/vi/$videoId/$quality.jpg';
  }
}
