// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as uri_launcher;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/src/iframe_api/src/functions/video_information.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'js_bridge.dart';
import 'webview_platform_stub.dart'
    if (dart.library.io) 'webview_platform_io.dart';
import 'youtube_player_event_handler.dart';

/// The Web Resource Error.
typedef YoutubeWebResourceError = WebResourceError;

Future<String> _buildPlayerHTML(Map<String, String> data) async {
  final playerHtml = await rootBundle.loadString(
    'packages/youtube_player_iframe/assets/player.html',
  );
  return playerHtml.replaceAllMapped(
    RegExp(r'<<([a-zA-Z]+)>>'),
    (m) => data[m.group(1)] ?? m.group(0)!,
  );
}

/// Controls the youtube player, and provides updates when the state is changing.
///
/// The video is displayed in a Flutter app by creating a [YoutubePlayer] widget.
///
/// After [YoutubePlayerController.close] all further calls are ignored.
class YoutubePlayerController implements YoutubePlayerIFrameAPI {
  /// Creates [YoutubePlayerController].
  YoutubePlayerController({
    this.params = const YoutubePlayerParams(),
    ValueChanged<YoutubeWebResourceError>? onWebResourceError,
    this.key,
    this.credentialless = false,
  }) {
    _eventHandler = YoutubePlayerEventHandler(this);

    final webViewParams = buildWebViewParams(credentialless: credentialless);

    final navigationDelegate = NavigationDelegate(
      onWebResourceError: (error) {
        log(error.description, name: error.errorType.toString());
        onWebResourceError?.call(error);
      },
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);
        return _decideNavigation(uri);
      },
    );

    webViewController =
        WebViewController.fromPlatformCreationParams(webViewParams)
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(navigationDelegate)
          ..setUserAgent(params.userAgent)
          ..addJavaScriptChannel(
            playerId,
            onMessageReceived: _eventHandler.call,
          )
          ..enableZoom(false);

    configureWebViewController(webViewController);

    _bridge = JsBridge(
      webViewController: webViewController,
      isReady: () => _eventHandler.isReady,
    );
  }

  /// Creates a [YoutubePlayerController] and initializes the player with [videoId].
  factory YoutubePlayerController.fromVideoId({
    required String videoId,
    YoutubePlayerParams params = const YoutubePlayerParams(),
    bool autoPlay = false,
    double? startSeconds,
    double? endSeconds,
    bool credentialless = false,
  }) {
    final controller = YoutubePlayerController(
      params: params,
      key: videoId,
      credentialless: credentialless,
    );

    if (autoPlay) {
      controller.loadVideoById(
        videoId: videoId,
        startSeconds: startSeconds,
        endSeconds: endSeconds,
      );
    } else {
      controller.cueVideoById(
        videoId: videoId,
        startSeconds: startSeconds,
        endSeconds: endSeconds,
      );
    }

    return controller;
  }

  /// The unique key for the player.
  final String? key;

  /// Defines player parameters for the youtube player.
  final YoutubePlayerParams params;

  /// Whether to use a credentialless iframe on web.
  ///
  /// When `true`, the iframe loads without cookies or storage access, which
  /// allows playback on pages with `Cross-Origin-Embedder-Policy` set.
  /// Has no effect on non-web platforms.
  final bool credentialless;

  /// The [WebViewController] that drives the player
  late final WebViewController webViewController;

  late final YoutubePlayerEventHandler _eventHandler;
  late final JsBridge _bridge;

  final StreamController<YoutubePlayerValue> _valueController =
      StreamController.broadcast();
  YoutubePlayerValue _value = YoutubePlayerValue();

  /// A Stream of [YoutubePlayerValue], which allows you to subscribe to changes
  /// in the controller value.
  Stream<YoutubePlayerValue> get stream => _valueController.stream;

  /// The [YoutubePlayerValue].
  YoutubePlayerValue get value => _value;

  @override
  Future<void> cuePlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  }) {
    return _bridge.run(
      'cuePlaylist',
      data: {
        list.length == 1 ? 'list' : 'playlist': list,
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
    return _bridge.run(
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
    return _bridge.run(
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
    return _bridge.run(
      'loadPlaylist',
      data: {
        list.length == 1 ? 'list' : 'playlist': list,
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
    return _bridge.run(
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
    return _bridge.run(
      'loadVideoByUrl',
      data: {
        'mediaContentUrl': mediaContentUrl,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
      },
    );
  }

  /// Loads the video with the given [url].
  ///
  /// Accepts any YouTube URL format: watch, youtu.be, /shorts/, /embed/,
  /// and music.youtube.com.
  Future<void> loadVideo(String url) {
    final videoId = convertUrlToId(url);

    assert(
      videoId != null && videoId.isNotEmpty,
      'Could not extract a video ID from the provided URL. '
      'Supported formats: watch, youtu.be, /shorts/, /embed/, music.youtube.com.',
    );

    final queryParams = Uri.tryParse(url)?.queryParameters ?? const {};

    return loadVideoById(
      videoId: videoId!,
      startSeconds: double.tryParse(queryParams['t'] ?? ''),
    );
  }

  /// Loads the player with default [params].
  @internal
  Future<void> init() async {
    await load(
      params: params,
      baseUrl: kIsWeb ? Uri.base.origin : (params.origin ?? params.host),
      id: playerId,
    );

    _bridge.completeInit();
  }

  /// Like [init] but accepts overridden [params] — for wrappers that need to
  /// force-disable native controls without changing the user-supplied params.
  Future<void> initWithParams({
    required YoutubePlayerParams params,
    String? baseUrl,
  }) async {
    await load(
      params: params,
      baseUrl:
          baseUrl ??
          (kIsWeb ? Uri.base.origin : (params.origin ?? params.host)),
      id: playerId,
    );

    _bridge.completeInit();
  }

  /// Loads the player with the given [params].
  ///
  /// [baseUrl] sets the origin for the iframe player.
  Future<void> load({
    required YoutubePlayerParams params,
    String? baseUrl,
    String id = 'player',
  }) async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
    final playerData = {
      'playerId': id,
      'pointerEvents': params.pointerEvents.name,
      'playerVars': params.toJson(),
      'platform': platform,
      'host': params.host,
      'videoStateUpdateInterval': params.videoStateUpdateInterval.toString(),
    };

    await webViewController.loadHtmlString(
      await _buildPlayerHTML(playerData),
      baseUrl: baseUrl,
    );
  }

  /// The unique player id.
  @internal
  late final String playerId = 'youtube_${key ?? hashCode}'.replaceAll(
    '-',
    '_',
  );

  /// MetaData for the currently loaded or cued video.
  YoutubeMetaData get metadata => _value.metaData;

  /// Creates new [YoutubePlayerValue] with assigned parameters and overrides
  /// the old one.
  void update({
    FullScreenOption? fullScreenOption,
    PlayerState? playerState,
    double? playbackRate,
    String? playbackQuality,
    YoutubeError? error,
    YoutubeMetaData? metaData,
  }) {
    if (_valueController.isClosed) return;
    _value = _value.copyWith(
      fullScreenOption: fullScreenOption,
      playerState: playerState,
      playbackRate: playbackRate,
      playbackQuality: playbackQuality,
      error: error,
      metaData: metaData,
    );
    _valueController.add(_value);
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

    const contentUrlPattern = r'^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?';
    const embedUrlPattern =
        r'^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/';
    const altUrlPattern = r'^https:\/\/youtu\.be\/';
    const shortsUrlPattern = r'^https:\/\/(?:www\.|m\.)?youtube\.com\/shorts\/';
    const musicUrlPattern = r'^https:\/\/(?:music\.)?youtube\.com\/watch\?';
    const idPattern = r'([_\-a-zA-Z0-9]{11}).*$';

    for (final regex in [
      '${contentUrlPattern}v=$idPattern',
      '$embedUrlPattern$idPattern',
      '$altUrlPattern$idPattern',
      '$shortsUrlPattern$idPattern',
      '$musicUrlPattern?v=$idPattern',
    ]) {
      if (RegExp(regex).firstMatch(url) case final match? when match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Grabs YouTube video's thumbnail for provided video id.
  static String getThumbnail({
    required String videoId,
    ThumbnailQuality quality = .standard,
    ThumbnailFormat format = .webp,
  }) {
    return format.buildUrl(videoId, quality.value);
  }

  @override
  Future<double> get duration async {
    final duration = await _bridge.runWithResult('getDuration');
    return double.tryParse(duration) ?? 0;
  }

  @override
  Future<List<String>> get playlist async {
    final playlist = await _bridge.evalWithResult('getPlaylist()');
    if (playlist.isEmpty) return [];
    try {
      final decoded = jsonDecode(playlist);
      if (decoded == null) return [];
      return List<String>.from(decoded);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<int> get playlistIndex async {
    final index = await _bridge.runWithResult('getPlaylistIndex');
    return int.tryParse(index) ?? 0;
  }

  @override
  Future<VideoData> get videoData async {
    final videoData = await _bridge.evalWithResult('getVideoData()');
    return VideoData.fromMap(jsonDecode(videoData));
  }

  @override
  Future<String> get videoEmbedCode {
    return _bridge.runWithResult('getVideoEmbedCode');
  }

  @override
  Future<String> get videoUrl async {
    final videoUrl = await _bridge.runWithResult('getVideoUrl');
    if (videoUrl.isEmpty) return '';
    try {
      final decoded = jsonDecode(videoUrl);
      return decoded is String ? decoded : videoUrl;
    } catch (_) {
      return videoUrl;
    }
  }

  @override
  Future<List<double>> get availablePlaybackRates async {
    final rates = await _bridge.evalWithResult('getAvailablePlaybackRates()');
    if (rates.isEmpty) return [];
    try {
      return List<num>.from(
        jsonDecode(rates),
      ).map((r) => r.toDouble()).toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<double> get playbackRate async {
    final rate = await _bridge.runWithResult('getPlaybackRate');
    return double.tryParse(rate) ?? 0;
  }

  @override
  Future<void> setLoop({required bool loopPlaylists}) {
    return _bridge.eval('player.setLoop($loopPlaylists)');
  }

  @override
  Future<void> setPlaybackRate(double suggestedRate) {
    return _bridge.eval('player.setPlaybackRate($suggestedRate)');
  }

  @override
  Future<void> setShuffle({required bool shufflePlaylists}) {
    return _bridge.eval('player.setShuffle($shufflePlaylists)');
  }

  @override
  Future<void> setSize(double width, double height) {
    return _bridge.eval('player.setSize($width, $height)');
  }

  @override
  Future<bool> get isMuted async {
    final isMuted = await _bridge.runWithResult('isMuted');
    return isMuted.toLowerCase() == 'true' || isMuted == '1';
  }

  @override
  Future<void> mute() {
    return _bridge.run('mute');
  }

  @override
  Future<void> nextVideo() {
    return _bridge.run('nextVideo');
  }

  @override
  Future<void> pauseVideo() {
    return _bridge.run('pauseVideo');
  }

  @override
  Future<void> playVideo() {
    return _bridge.run('playVideo');
  }

  @override
  Future<void> playVideoAt(int index) {
    return _bridge.eval('player.playVideoAt($index)');
  }

  @override
  Future<void> previousVideo() {
    return _bridge.run('previousVideo');
  }

  @override
  Future<void> seekTo({required double seconds, bool allowSeekAhead = false}) {
    return _bridge.eval('player.seekTo($seconds, $allowSeekAhead)');
  }

  @override
  Future<void> setVolume(int volume) {
    return _bridge.eval('player.setVolume($volume)');
  }

  @override
  Future<void> stopVideo() {
    return _bridge.run('stopVideo');
  }

  @override
  Future<void> unMute() {
    return _bridge.run('unMute');
  }

  @override
  Future<int> get volume async {
    final volume = await _bridge.runWithResult('getVolume');
    return int.tryParse(volume) ?? 0;
  }

  @override
  Future<double> get currentTime async {
    final time = await _bridge.runWithResult('getCurrentTime');
    return double.tryParse(time) ?? 0;
  }

  @override
  Future<PlayerState> get playerState async {
    final stateCode = await _bridge.runWithResult('getPlayerState');
    return PlayerState.fromCode(int.tryParse(stateCode) ?? -2);
  }

  @override
  Future<double> get videoLoadedFraction async {
    final loadedFraction = await _bridge.runWithResult(
      'getVideoLoadedFraction',
    );
    return double.tryParse(loadedFraction) ?? 0;
  }

  /// Enters fullscreen mode.
  ///
  /// If [lock] is true, auto rotate will be disabled.
  void enterFullScreen({bool lock = true}) {
    update(fullScreenOption: FullScreenOption(enabled: true, locked: lock));
    _onFullscreenChanged?.call(true);
  }

  /// Exits fullscreen mode.
  ///
  /// If [lock] is true, auto rotate will be disabled.
  void exitFullScreen({bool lock = true}) {
    update(fullScreenOption: FullScreenOption(enabled: false, locked: lock));
    _onFullscreenChanged?.call(false);
  }

  ValueChanged<bool>? _onFullscreenChanged;

  /// Sets the full screen listener.
  // ignore: use_setters_to_change_properties
  void setFullScreenListener(ValueChanged<bool> callback) {
    _onFullscreenChanged = callback;
  }

  /// Toggles fullscreen mode.
  ///
  /// If [lock] is true, auto rotate will be disabled.
  void toggleFullScreen({bool lock = true}) {
    if (value.fullScreenOption.enabled) {
      exitFullScreen(lock: lock);
    } else {
      enterFullScreen(lock: lock);
    }
  }

  /// The stream for [YoutubeVideoState] changes.
  Stream<YoutubeVideoState> get videoStateStream {
    return _eventHandler.videoStateController.stream;
  }

  /// Creates a stream that repeatedly emits current time at [period] intervals.
  @Deprecated('Use videoStateStream instead')
  Stream<Duration> getCurrentPositionStream({
    // Unused
    Duration period = const Duration(seconds: 1),
  }) {
    return videoStateStream.map((state) => state.position);
  }

  NavigationDecision _decideNavigation(Uri? uri) {
    if (uri == null) return NavigationDecision.prevent;

    final queryParams = uri.queryParameters;
    final host = uri.host;
    final path = uri.path;

    String? featureName;
    if (host.contains('facebook') ||
        host.contains('twitter') ||
        host == 'youtu') {
      featureName = 'social';
    } else if (queryParams.containsKey('feature')) {
      featureName = queryParams['feature'];
    } else if (path == '/watch') {
      featureName = 'emb_info';
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return NavigationDecision.navigate;
    }

    switch (featureName) {
      case 'emb_rel_pause' || 'emb_rel_end' || 'emb_info':
        final videoId = queryParams['v'];
        if (videoId != null) loadVideoById(videoId: videoId);
      case 'emb_title' || 'emb_logo' || 'social' || 'wl_button':
        uri_launcher.launchUrl(uri);
    }

    return NavigationDecision.prevent;
  }

  /// Disposes the resources created by [YoutubePlayerController].
  Future<void> close() async {
    if (_bridge.isInitCompleted) {
      try {
        await stopVideo();
      } catch (_) {
        // Player may be in an errored or disposed state; ignore stop failure.
      }
    }
    await webViewController.removeJavaScriptChannel(playerId);
    await _eventHandler.videoStateController.close();
    await _valueController.close();
  }
}
