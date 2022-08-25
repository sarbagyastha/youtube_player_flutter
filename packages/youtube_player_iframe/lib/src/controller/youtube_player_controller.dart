import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/src/iframe_api/src/functions/video_information.dart';
import 'package:youtube_player_iframe/src/player_value.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_player_iframe_web/youtube_player_iframe_web.dart';

import 'youtube_player_event_handler.dart';

/// Controls the youtube player, and provides updates when the state is changing.
///
/// The video is displayed in a Flutter app by creating a [YoutubePlayer] widget.
///
/// After [YoutubePlayerController.close] all further calls are ignored.
class YoutubePlayerController implements YoutubePlayerIFrameAPI {
  /// Creates [YoutubePlayerController].
  YoutubePlayerController({
    this.params = const YoutubePlayerParams(),
  }) {
    registerYoutubePlayerIframeWeb();
    _eventHandler = YoutubePlayerEventHandler(this);
    javaScriptChannels = _eventHandler.javascriptChannels;
  }

  /// Creates a [YoutubePlayerController] and initializes the player with [videoId].
  factory YoutubePlayerController.fromVideoId({
    required String videoId,
    YoutubePlayerParams params = const YoutubePlayerParams(),
    bool autoPlay = false,
    double? startSeconds,
    double? endSeconds,
  }) {
    final controller = YoutubePlayerController(params: params);

    return controller
      ..onInit = () {
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
      };
  }

  /// Defines player parameters for the youtube player.
  final YoutubePlayerParams params;

  Completer<WebViewController> _webViewControllerCompleter = Completer();

  late final YoutubePlayerEventHandler _eventHandler;

  /// The set of [JavascriptChannel]s available to JavaScript code running in the player iframe.
  late final Set<JavascriptChannel> javaScriptChannels;

  final StreamController<YoutubePlayerValue> _valueController =
      StreamController.broadcast();
  YoutubePlayerValue _value = YoutubePlayerValue();

  /// A Stream of [YoutubePlayerValue], which allows you to subscribe to changes
  /// in the controller value.
  Stream<YoutubePlayerValue> get stream => _valueController.stream;

  /// The [YoutubePlayerValue].
  YoutubePlayerValue get value => _value;

  /// Gets the [WebViewController] for the iframe player.
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

  /// Loads the video with the given [url].
  ///
  /// The [url] must be a valid youtube video watch url.
  /// i.e. https://www.youtube.com/watch?v=VIDEO_ID
  Future<void> loadVideo(String url) {
    assert(
      RegExp(r'^https://(?:www\.|m\.)?youtube\.com/watch.*').hasMatch(url),
      'Only YouTube watch URLs are supported.',
    );

    final params = Uri.parse(url).queryParameters;
    final videoId = params['v'];

    assert(
      videoId != null && videoId.isNotEmpty,
      'Video ID is missing from the provided url.',
    );

    return loadVideoById(
      videoId: videoId!,
      startSeconds: double.tryParse(params['t'] ?? ''),
    );
  }

  /// Loads the player with default [params].
  @internal
  Future<void> init(WebViewController controller) async {
    _webViewControllerCompleter = Completer();
    await controller.runJavascript('var isWeb = $kIsWeb;');
    _webViewControllerCompleter.complete(controller);
    await load(params: params, baseUrl: params.origin);

    _eventHandler.reset();
    await onInit();
  }

  /// Loads the player with the given [params].
  ///
  /// [baseUrl] sets the origin for the iframe player.
  Future<void> load({
    required YoutubePlayerParams params,
    String? baseUrl,
  }) async {
    final playerHtml = await rootBundle.loadString(
      'packages/youtube_player_iframe/assets/player.html',
    );

    final controller = await _webViewControllerCompleter.future;
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();

    await controller.loadHtmlString(
      playerHtml
          .replaceFirst('<<playerVars>>', params.toJson())
          .replaceFirst('<<platform>>', platform)
          .replaceFirst('<<host>>', params.origin ?? 'https://www.youtube.com'),
      baseUrl: baseUrl,
    );
  }

  Future<void> _run(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    final varArgs = await _prepareData(data);
    final controller = await _webViewControllerCompleter.future;

    return controller.runJavascript('player.$functionName($varArgs);');
  }

  Future<String> _runWithResult(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    final varArgs = await _prepareData(data);
    final controller = await _webViewControllerCompleter.future;

    return controller.runJavascriptReturningResult(
      'player.$functionName($varArgs);',
    );
  }

  Future<void> _eval(String javascript) async {
    await _eventHandler.isReady;

    final controller = await _webViewControllerCompleter.future;
    return controller.runJavascript(javascript);
  }

  Future<String> _evalWithResult(String javascript) async {
    await _eventHandler.isReady;

    final controller = await _webViewControllerCompleter.future;
    return controller.runJavascriptReturningResult(javascript);
  }

  Future<String> _prepareData(Map<String, dynamic>? data) async {
    await _eventHandler.isReady;
    return data == null ? '' : jsonEncode(data);
  }

  /// MetaData for the currently loaded or cued video.
  YoutubeMetaData get metadata => _value.metaData;

  /// Creates new [YoutubePlayerValue] with assigned parameters and overrides
  /// the old one.
  void update({
    FullScreenOption? fullScreenOption,
    int? volume,
    PlayerState? playerState,
    double? playbackRate,
    String? playbackQuality,
    YoutubeError? error,
    YoutubeMetaData? metaData,
  }) {
    final updatedValue = YoutubePlayerValue(
      fullScreenOption: fullScreenOption ?? value.fullScreenOption,
      volume: volume ?? value.volume,
      playerState: playerState ?? value.playerState,
      playbackRate: playbackRate ?? value.playbackRate,
      playbackQuality: playbackQuality ?? value.playbackQuality,
      error: error ?? value.error,
      metaData: metaData ?? value.metaData,
    );

    _valueController.add(updatedValue);
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

    const contentUrlPattern = r'^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?';
    const embedUrlPattern =
        r'^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/';
    const altUrlPattern = r'^https:\/\/youtu\.be\/';
    const shortsUrlPattern = r'^https:\/\/(?:www\.|m\.)?youtube\.com\/shorts\/';
    const idPattern = r'([_\-a-zA-Z0-9]{11}).*$';

    for (var regex in [
      '${contentUrlPattern}v=$idPattern',
      '$embedUrlPattern$idPattern',
      '$altUrlPattern$idPattern',
      '$shortsUrlPattern$idPattern',
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

  @override
  Future<double> get duration async {
    final duration = await _runWithResult('getDuration');
    return double.tryParse(duration) ?? 0;
  }

  @override
  Future<List<String>> get playlist async {
    final playlist = await _evalWithResult('getPlaylist()');

    return List.from(jsonDecode(playlist));
  }

  @override
  Future<int> get playlistIndex async {
    final index = await _runWithResult('getPlaylistIndex');

    return int.tryParse(index) ?? 0;
  }

  @override
  Future<VideoData> get videoData async {
    final videoData = await _evalWithResult('getVideoData()');

    return VideoData.fromMap(jsonDecode(videoData));
  }

  @override
  Future<String> get videoEmbedCode {
    return _runWithResult('getVideoEmbedCode');
  }

  @override
  Future<String> get videoUrl async {
    final videoUrl = await _runWithResult('getVideoUrl');

    if (videoUrl.startsWith('"')) {
      return videoUrl.substring(1, videoUrl.length - 1);
    }

    return videoUrl;
  }

  @override
  Future<List<double>> get availablePlaybackRates async {
    final rates = await _evalWithResult('getAvailablePlaybackRates()');

    return List<num>.from(jsonDecode(rates))
        .map((r) => r.toDouble())
        .toList(growable: false);
  }

  @override
  Future<double> get playbackRate async {
    final rate = await _runWithResult('getPlaybackRate');

    return double.tryParse(rate) ?? 0;
  }

  @override
  Future<void> setLoop({required bool loopPlaylists}) {
    return _eval('player.setLoop($loopPlaylists)');
  }

  @override
  Future<void> setPlaybackRate(double suggestedRate) {
    return _eval('player.setPlaybackRate($suggestedRate)');
  }

  @override
  Future<void> setShuffle({required bool shufflePlaylists}) {
    return _eval('player.setShuffle($shufflePlaylists)');
  }

  @override
  Future<void> setSize(double width, double height) {
    return _eval('player.setSize($width, $height)');
  }

  @override
  Future<bool> get isMuted async {
    final isMuted = await _runWithResult('isMuted');
    return isMuted == '1';
  }

  @override
  Future<void> mute() {
    return _run('mute');
  }

  @override
  Future<void> nextVideo() {
    return _run('nextVideo');
  }

  @override
  Future<void> pauseVideo() {
    return _run('pauseVideo');
  }

  @override
  Future<void> playVideo() {
    return _run('playVideo');
  }

  @override
  Future<void> playVideoAt(int index) {
    return _eval('player.playVideoAt($index)');
  }

  @override
  Future<void> previousVideo() {
    return _run('previousVideo');
  }

  @override
  Future<void> seekTo({required double seconds, bool allowSeekAhead = false}) {
    return _eval('player.seekTo($seconds, $allowSeekAhead)');
  }

  @override
  Future<void> setVolume(int volume) {
    return _eval('player.setVolume($volume)');
  }

  @override
  Future<void> stopVideo() {
    return _run('stopVideo');
  }

  @override
  Future<void> unMute() {
    return _run('unMute');
  }

  @override
  Future<int> get volume async {
    final volume = await _runWithResult('getVolume');

    return int.tryParse(volume) ?? 0;
  }

  @override
  Future<double> get currentTime async {
    final time = await _runWithResult('getCurrentTime');

    return double.tryParse(time) ?? 0;
  }

  @override
  Future<PlayerState> get playerState async {
    final stateCode = await _runWithResult('getPlayerState');

    return PlayerState.values.firstWhere(
      (state) => state.code.toString() == stateCode,
      orElse: () => PlayerState.unknown,
    );
  }

  @override
  Future<double> get videoLoadedFraction async {
    final loadedFraction = await _runWithResult('getVideoLoadedFraction');

    return double.tryParse(loadedFraction) ?? 0;
  }

  /// Enters fullscreen mode.
  ///
  /// If [lock] is true, auto rotate will be disabled.
  void enterFullScreen({bool lock = true}) {
    update(fullScreenOption: FullScreenOption(enabled: true, locked: lock));
    onFullscreenChange(true);
  }

  /// Exits fullscreen mode.
  ///
  /// If [lock] is true, auto rotate will be disabled.
  void exitFullScreen({bool lock = true}) {
    update(fullScreenOption: FullScreenOption(enabled: false, locked: lock));
    onFullscreenChange(false);
  }

  /// Called when full screen mode for the player changes.
  void Function(bool isFullscreen) onFullscreenChange = (_) {};

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

  /// Creates a stream that repeatedly emits current time at [period] intervals.
  Stream<Duration> getCurrentPositionStream({
    Duration period = const Duration(seconds: 1),
  }) async* {
    yield _getDurationFrom(seconds: await currentTime);

    yield* Stream.periodic(period).asyncMap(
      (_) async => _getDurationFrom(seconds: await currentTime),
    );
  }

  Duration _getDurationFrom({required double seconds}) {
    final timeInMs = (seconds * 1000).truncate();

    return Duration(milliseconds: timeInMs);
  }

  /// Called when the player is created.
  FutureOr<void> Function() onInit = () {};

  /// Disposes the resources created by [YoutubePlayerController].
  void close() => _valueController.close();
}