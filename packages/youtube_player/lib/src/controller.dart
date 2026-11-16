// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

import 'iframe_api.dart';
import 'params.dart';
import 'value.dart';

/// What happens to a click on the player UI. See
/// [YoutubePlayerController.onNavigationRequest].
enum NavigationDecision {
  /// Let the click through: a related video loads in place, other links open
  /// externally, and buttons (e.g. share) act as usual.
  navigate,

  /// Block the click. Return this after handling the click yourself.
  prevent,
}

/// Decides what happens when the user clicks [NavigationRequest.element].
typedef NavigationRequestHandler = FutureOr<NavigationDecision> Function(
  NavigationRequest request,
);

/// Whether a player UI [element] is shown. See
/// [YoutubePlayerController.elementVisibility].
typedef ElementVisibility = bool Function(PlayerElement element);

/// Controls one YouTube player.
///
/// Create it once (e.g. in `initState`), pass it to a `YoutubePlayer` widget,
/// and [close] it when done. The native player is created when a
/// `YoutubePlayer` first shows it, so idle controllers cost nothing. Calls
/// made before the player is ready are queued and run in order.
class YoutubePlayerController({
  /// Player configuration.
  final YoutubePlayerParams params = const YoutubePlayerParams(),

  /// Called when the page or the IFrame API fails to load.
  final void Function(YoutubeLoadError error)? onLoadError,

  /// Decides which of YouTube's own player UI elements are shown, e.g.
  /// `(e) => e != PlayerElement.youtubeLogo`.
  ///
  /// Asked once for each of [PlayerElement.values] and
  /// [YoutubePlayerParams.customElements] when the player is created; change
  /// visibility later with [setElementVisible]. Android, iOS and macOS only.
  ///
  /// YouTube's terms restrict obscuring player branding; hiding elements is
  /// at your own risk.
  final ElementVisibility? elementVisibility,

  /// Decides what happens when the user clicks the player UI: links that
  /// leave the player (title, channel, logo, related videos) and, on Android,
  /// iOS and macOS, buttons such as share or watch later.
  ///
  /// [NavigationRequest.element] says what was clicked. Without a handler,
  /// related videos load in place and other links open externally. On the
  /// web, links always open in a new tab and this is never called.
  final NavigationRequestHandler? onNavigationRequest,

  /// An arbitrary key, e.g. for lists of players.
  final String? key,
}) implements YoutubePlayerIFrameAPI {
  /// Creates a controller with [videoId] cued, or playing when [autoPlay].
  ///
  /// With `YoutubePlayer.autoPlayWhenVisible` (the default) autoplay waits
  /// until the player is at least half visible, per YouTube's Required
  /// Minimum Functionality.
  factory fromVideoId({
    required String videoId,
    YoutubePlayerParams params = const YoutubePlayerParams(),
    bool autoPlay = false,
    double? startSeconds,
    double? endSeconds,
    void Function(YoutubeLoadError error)? onLoadError,
    ElementVisibility? elementVisibility,
    NavigationRequestHandler? onNavigationRequest,
  }) {
    final controller = YoutubePlayerController(
      params: params,
      onLoadError: onLoadError,
      elementVisibility: elementVisibility,
      onNavigationRequest: onNavigationRequest,
      key: videoId,
    ).._initialVideoId = videoId;
    // Whole seconds go into the embed as `start` / `end`, so the video
    // loads once. Fractions need a cue after ready.
    if (_isWhole(startSeconds) && _isWhole(endSeconds)) {
      controller
        .._start = startSeconds?.toInt()
        .._end = endSeconds?.toInt();
    } else {
      controller.cueVideoById(
        videoId: videoId,
        startSeconds: startSeconds,
        endSeconds: endSeconds,
      );
    }
    controller._autoPlayPending = autoPlay;
    return controller;
  }

  /// The video passed to [YoutubePlayerController.fromVideoId], if any.
  String? get initialVideoId => _initialVideoId;
  String? _initialVideoId;
  int? _start;
  int? _end;

  static bool _isWhole(double? seconds) =>
      seconds == null || seconds == seconds.roundToDouble();

  final _valueController = StreamController<YoutubePlayerValue>.broadcast();
  final _videoStateController = StreamController<YoutubeVideoState>.broadcast();
  final _apiChangeController = StreamController<void>.broadcast();
  final _ready = Completer<YoutubePlayerHost>();
  final _hostCompleter = Completer<YoutubePlayerHost>();
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _pendingCalls = <(PlayerMethod, List<Object?>)>[];

  late YoutubePlayerValue _value = YoutubePlayerValue(isMuted: params.mute);
  ValueChanged<bool>? _fullScreenListener;
  YoutubePlayerHost? _host;
  var _closed = false;
  var _autoPlayPending = false;

  /// Hidden elements by name; `null` until [elementVisibility] is resolved.
  Map<String, PlayerElement>? _hiddenByName;
  var _warnedUnsupported = false;

  // Cached by events, so the common getters never round-trip.
  var _currentTime = 0.0;
  var _loadedFraction = 0.0;
  var _duration = 0.0;
  VideoData _videoData = const VideoData();

  static YoutubePlayerController? _autoPlaying;

  var _initStarted = false;

  void _ensureInit() {
    if (_initStarted || _closed) return;
    _initStarted = true;
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      final host = await YoutubePlayerPlatform.instance.createHost(
        params.toHostParams(
          hiddenElements: _hidden.values.toSet(),
          interceptButtons: onNavigationRequest != null,
          videoId: initialVideoId,
          customControls: customControls,
          backgroundColor: backgroundColor,
          start: _start,
          end: _end,
        ),
      );
      if (_closed) {
        host.dispose();
        return;
      }
      _host = host;
      if (elementVisibility != null ||
          onNavigationRequest != null ||
          _hidden.isNotEmpty) {
        _warnIfUnsupported(host);
      }
      _subscriptions
        ..add(host.events.listen(_onEvent))
        ..add(host.navigations.listen(_onNavigation))
        ..add(host.fullscreenChanges.listen(_onFullscreen));
      _hostCompleter.complete(host);
    } catch (error) {
      final loadError = YoutubeLoadError(description: '$error');
      _emit(_value.copyWith(loadError: loadError));
      onLoadError?.call(loadError);
    }
  }

  // MARK: State

  /// The latest player state.
  YoutubePlayerValue get value => _value;

  /// Player state changes.
  Stream<YoutubePlayerValue> get stream => _valueController.stream;

  /// Listens to player state changes.
  StreamSubscription<YoutubePlayerValue> listen(
    void Function(YoutubePlayerValue value)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  /// Position and buffering updates while playing, at
  /// [YoutubePlayerParams.videoStateUpdateInterval].
  Stream<YoutubeVideoState> get videoStateStream =>
      _videoStateController.stream;

  /// Fires when a player module (e.g. captions) loads or unloads.
  Stream<void> get apiChangeStream => _apiChangeController.stream;

  /// Metadata of the current video.
  YoutubeMetaData get metadata => _value.metaData;

  /// Whether the native controls, keyboard, fullscreen button and pointer
  /// events are turned off for a Flutter overlay. Set by `YoutubePlayer`
  /// before it reads [host]; it only applies when the player is created.
  @internal
  var customControls = false;

  /// Shown behind the player while it loads. Set by `YoutubePlayer` before
  /// it reads [host]; later changes go through the host directly.
  @internal
  Color? backgroundColor;

  /// The platform host, created on first access.
  @internal
  Future<YoutubePlayerHost> get host {
    _ensureInit();
    return _hostCompleter.future;
  }

  void _emit(YoutubePlayerValue value) {
    if (_closed || value == _value) return;
    _value = value;
    _valueController.add(value);
  }

  void _onEvent(PlayerEvent event) {
    switch (event) {
      case ReadyEvent():
        _emit(_value.copyWith(isReady: true));
        if (!_ready.isCompleted) {
          final host = _host!;
          for (final (method, args) in _pendingCalls) {
            host.call(method, args);
          }
          _pendingCalls.clear();
          _ready.complete(host);
        }
      case StateChangeEvent(
        :final state,
        :final videoData,
        :final duration,
        :final playbackRate,
      ):
        var meta = _value.metaData;
        if (videoData case final data? when data.videoId.isNotEmpty) {
          _videoData = data;
          meta = meta.copyWith(
            videoId: data.videoId,
            title: data.title,
            author: data.author,
          );
        }
        if (duration case final seconds? when seconds > 0) {
          _duration = seconds;
          meta = meta.copyWith(duration: _toDuration(seconds));
        }
        final freshVideo = state == .unStarted || state == .cued;
        _emit(
          _value.copyWith(
            playerState: state,
            metaData: meta,
            // Prefer the rate the player reports; older pages don't.
            playbackRate: playbackRate ?? (freshVideo ? 1 : null),
            error: state == .playing ? .none : null,
            isAutoplayBlocked: state == .playing ? false : null,
          ),
        );
      case PlaybackRateChangeEvent(:final rate):
        _emit(_value.copyWith(playbackRate: rate));
      case PlaybackQualityChangeEvent(:final quality):
        _emit(_value.copyWith(playbackQuality: quality));
      case ErrorEvent(:final error):
        _emit(_value.copyWith(error: error));
      case AutoplayBlockedEvent():
        _emit(_value.copyWith(isAutoplayBlocked: true));
      case ApiChangeEvent():
        _apiChangeController.add(null);
      case LoadErrorEvent(:final error):
        _emit(_value.copyWith(loadError: error));
        onLoadError?.call(error);
      case TickEvent():
        _currentTime = event.currentTime;
        _loadedFraction = event.loadedFraction;
        if (_videoStateController.hasListener) {
          _videoStateController.add(
            YoutubeVideoState(
              position: _toDuration(event.currentTime),
              loadedFraction: event.loadedFraction,
            ),
          );
        }
        var meta = _value.metaData;
        if (event.duration > 0 && event.duration != _duration) {
          _duration = event.duration;
          meta = meta.copyWith(duration: _toDuration(event.duration));
        }
        // No-op (deduplicated) unless duration or volume actually changed.
        _emit(
          _value.copyWith(
            metaData: meta,
            isMuted: event.muted,
            volume: event.volume,
          ),
        );
    }
  }

  Future<void> _onNavigation(NavigationRequest request) async {
    // Hand back the app's own element instances (e.g. custom ones).
    final element = request.element;
    if (_known(element.name) case final known? when known != element) {
      request = NavigationRequest(
        uri: request.uri,
        element: known,
        clickId: request.clickId,
      );
    }
    var decision = NavigationDecision.navigate;
    if (onNavigationRequest case final handler?) {
      try {
        decision = await handler(request);
      } catch (error, stack) {
        decision = .prevent;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'youtube_player',
            context: ErrorDescription('while handling $request'),
          ),
        );
      }
    }
    final allow = decision == .navigate;
    if (request.clickId case final id?) {
      // A held button click: replay or drop it in the player.
      if (!_closed) _host?.resolveClick(id, allow: allow);
      return;
    }
    final uri = request.uri;
    if (!allow || uri == null || _closed) return;
    if (relatedVideoId(uri) case final videoId?) {
      loadVideoById(videoId: videoId);
      return;
    }
    await launchUrl(uri, mode: .externalApplication);
  }

  // MARK: Player UI elements

  Map<String, PlayerElement> get _hidden => _hiddenByName ??= {
    for (final e in [...PlayerElement.values, ...params.customElements])
      if (elementVisibility?.call(e) == false) e.name: e,
  };

  PlayerElement? _known(String name) {
    if (_hidden[name] case final hidden?) return hidden;
    for (final e in params.customElements) {
      if (e.name == name) return e;
    }
    return null;
  }

  /// Whether [element] is shown, per [elementVisibility] and
  /// [setElementVisible]. Elements are matched by [PlayerElement.name].
  bool isElementVisible(PlayerElement element) =>
      !_hidden.containsKey(element.name);

  /// Shows or hides one of YouTube's own player UI [element]s, e.g. the
  /// logo. Overrides [elementVisibility]. Android, iOS and macOS only.
  void setElementVisible(PlayerElement element, bool visible) {
    if (_closed) return;
    final hidden = _hidden;
    if (visible) {
      if (hidden.remove(element.name) == null) return;
    } else {
      if (identical(hidden[element.name], element)) return;
      hidden[element.name] = element;
    }
    // Before the player exists, the next host picks it up at creation.
    if (_host case final host?) {
      _warnIfUnsupported(host);
      host.setHiddenElements(hidden.values.toSet());
    }
  }

  void _warnIfUnsupported(YoutubePlayerHost host) {
    if (host.supportsElementControl || _warnedUnsupported) return;
    _warnedUnsupported = true;
    debugPrint(
      'youtube_player: hiding or intercepting player UI elements is not '
      'supported on this platform${kIsWeb ? ' (web)' : ''}; ignoring.',
    );
  }

  void _onFullscreen(bool isFullScreen) {
    _emit(_value.copyWith(isFullScreen: isFullScreen));
    _fullScreenListener?.call(isFullScreen);
  }

  // MARK: Command plumbing

  /// Runs [method] now if the player is ready, otherwise queues it until
  /// [ReadyEvent]. Calls keep their order.
  void _run(PlayerMethod method, [List<Object?> args = const []]) {
    if (_closed) return;
    if (_ready.isCompleted) {
      _host?.call(method, args);
    } else {
      _pendingCalls.add((method, args));
    }
  }

  Future<Object?> _query(
    PlayerMethod method, [
    List<Object?> args = const [],
  ]) async {
    if (_closed) return null;
    try {
      final host = await _ready.future;
      return await host.query(method, args);
    } on _Closed {
      return null;
    } on StateError {
      return null;
    } on TimeoutException {
      return null;
    }
  }

  static Duration _toDuration(double seconds) => Duration(
    microseconds: (seconds * Duration.microsecondsPerSecond).round(),
  );

  static double _toDouble(Object? value) => (value as num?)?.toDouble() ?? 0;

  // MARK: Autoplay (Required Minimum Functionality)

  /// Starts the pending `fromVideoId(autoPlay: true)` playback, pausing any
  /// other auto-playing player so only one autoplays at a time.
  @internal
  void startPendingAutoPlay() {
    if (!_autoPlayPending || _closed) return;
    _autoPlayPending = false;
    final previous = _autoPlaying;
    if (previous != null && previous != this && !previous._closed) {
      previous.pauseVideo();
    }
    _autoPlaying = this;
    playVideo();
  }

  /// Whether `fromVideoId(autoPlay: true)` playback is still waiting.
  @internal
  bool get hasPendingAutoPlay => _autoPlayPending;

  // MARK: Queueing

  Map<String, Object> _video(
    String key,
    String value,
    double? start,
    double? end,
  ) => {key: value, 'startSeconds': ?start, 'endSeconds': ?end};

  /// Video-id arrays only work with the argument syntax
  /// `cuePlaylist(ids, index, startSeconds)`; the object syntax silently
  /// ignores them. Playlist / channel ids use the object syntax.
  List<Object> _list(
    List<String> list,
    ListType? type,
    int? index,
    double? start,
  ) => type == null
      ? [list, index ?? 0, start ?? 0]
      : [
          {
            'listType': type.value,
            'list': list.first,
            'index': ?index,
            'startSeconds': ?start,
          },
        ];

  @override
  void cueVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  }) => _run(.cueVideoById, [
    _video('videoId', videoId, startSeconds, endSeconds),
  ]);

  @override
  void loadVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  }) => _run(.loadVideoById, [
    _video('videoId', videoId, startSeconds, endSeconds),
  ]);

  @override
  void cueVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  }) => _run(.cueVideoByUrl, [
    _video('mediaContentUrl', mediaContentUrl, startSeconds, endSeconds),
  ]);

  @override
  void loadVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  }) => _run(.loadVideoByUrl, [
    _video('mediaContentUrl', mediaContentUrl, startSeconds, endSeconds),
  ]);

  @override
  void cuePlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  }) => _run(.cuePlaylist, _list(list, listType, index, startSeconds));

  @override
  void loadPlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  }) => _run(.loadPlaylist, _list(list, listType, index, startSeconds));

  /// Loads the video in any common YouTube [url] form (watch, youtu.be,
  /// embed, shorts, live).
  void loadVideo(String url) {
    final videoId = convertUrlToId(url);
    assert(videoId != null, 'No YouTube video id in $url');
    if (videoId != null) loadVideoById(videoId: videoId);
  }

  // MARK: Playback

  @override
  void playVideo() => _run(.playVideo);

  @override
  void pauseVideo() => _run(.pauseVideo);

  @override
  void stopVideo() => _run(.stopVideo);

  @override
  void seekTo({required double seconds, bool allowSeekAhead = false}) =>
      _run(.seekTo, [seconds, allowSeekAhead]);

  @override
  void nextVideo() => _run(.nextVideo);

  @override
  void previousVideo() => _run(.previousVideo);

  @override
  void playVideoAt(int index) => _run(.playVideoAt, [index]);

  // MARK: Volume

  @override
  void mute() => _run(.mute);

  @override
  void unMute() => _run(.unMute);

  @override
  bool get isMuted => _value.isMuted;

  @override
  void setVolume(int volume) {
    assert(volume >= 0 && volume <= 100, 'Volume must be within 0..100');
    _run(.setVolume, [volume.clamp(0, 100)]);
  }

  @override
  int get volume => _value.volume;

  /// Whether [setVolume] can change the volume on this platform.
  ///
  /// False on iOS (including browsers on iOS), where only the hardware
  /// buttons change media volume; [mute] and [unMute] still work there.
  /// iPads that request desktop sites report macOS in the browser, so this
  /// is true there on the web even though volume can't be set.
  bool get supportsVolume => defaultTargetPlatform != .iOS;

  // MARK: Size, rate, playlist behaviour

  @override
  void setSize(double width, double height) => _run(.setSize, [width, height]);

  @override
  double get playbackRate => _value.playbackRate;

  @override
  void setPlaybackRate(double suggestedRate) =>
      _run(.setPlaybackRate, [suggestedRate]);

  @override
  Future<List<double>> get availablePlaybackRates async =>
      switch (await _query(.getAvailablePlaybackRates)) {
        final List<Object?> rates => [for (final r in rates) _toDouble(r)],
        _ => const [1],
      };

  @override
  void setLoop({required bool loopPlaylists}) =>
      _run(.setLoop, [loopPlaylists]);

  @override
  void setShuffle({required bool shufflePlaylists}) =>
      _run(.setShuffle, [shufflePlaylists]);

  // MARK: Status and information

  @override
  PlayerState get playerState => _value.playerState;

  @override
  double get currentTime => _currentTime;

  @override
  double get videoLoadedFraction => _loadedFraction;

  @override
  double get duration => _duration;

  @override
  VideoData get videoData => _videoData;

  @override
  Future<String> get videoUrl async =>
      await _query(.getVideoUrl) as String? ?? '';

  @override
  Future<String> get videoEmbedCode async =>
      await _query(.getVideoEmbedCode) as String? ?? '';

  @override
  Future<List<String>> get playlist async =>
      switch (await _query(.getPlaylist)) {
        final List<Object?> ids => ids.whereType<String>().toList(),
        _ => const [],
      };

  @override
  Future<int> get playlistIndex async =>
      (await _query(.getPlaylistIndex) as num?)?.toInt() ?? -1;

  // MARK: Modules and 360°

  @override
  void setCaptionsFontSize(int size) =>
      _run(.setOption, ['captions', 'fontSize', size]);

  @override
  void reloadCaptions() => _run(.setOption, ['captions', 'reload', true]);

  @override
  Future<List<String>> getOptions([String? module]) async =>
      switch (await _query(.getOptions, [?module])) {
        final List<Object?> names => names.whereType<String>().toList(),
        _ => const [],
      };

  @override
  Future<SphericalProperties> get sphericalProperties async =>
      switch (await _query(.getSphericalProperties)) {
        final Map<Object?, Object?> json => .fromJson(json),
        _ => const SphericalProperties(),
      };

  @override
  void setSphericalProperties(SphericalProperties properties) =>
      _run(.setSphericalProperties, [properties.toJson()]);

  // MARK: Fullscreen (owned by the platform WebView)

  /// Asks the platform to present the player fullscreen.
  ///
  /// Returns whether the request was accepted. Platforms may refuse requests
  /// that do not come from a user gesture (and iPhone only supports the
  /// fullscreen button inside the player); in that case nothing changes.
  Future<bool> enterFullScreen() async =>
      await _query(.requestFullscreen) == true;

  /// Leaves fullscreen if it is active.
  void exitFullScreen() {
    if (!_closed) _host?.exitFullscreen();
  }

  /// Toggles fullscreen; see [enterFullScreen].
  void toggleFullScreen() {
    if (_value.isFullScreen) {
      exitFullScreen();
    } else {
      unawaited(enterFullScreen());
    }
  }

  /// Called on every fullscreen transition.
  void setFullScreenListener(ValueChanged<bool> callback) {
    _fullScreenListener = callback;
  }

  // MARK: Utilities

  /// Extracts the video id from common YouTube URL forms, or returns `null`.
  static String? convertUrlToId(String url, {bool trimWhitespaces = true}) {
    final input = trimWhitespaces ? url.trim() : url;
    if (_idPattern.hasMatch(input)) return input;
    final uri = Uri.tryParse(input);
    if (uri == null) return null;
    final host = uri.host.replaceFirst(RegExp(r'^(www\.|m\.|music\.)'), '');
    final id = switch ((host, uri.pathSegments)) {
      ('youtu.be', [final id, ...]) => id,
      ('youtube.com' || 'youtube-nocookie.com', ['watch']) =>
        uri.queryParameters['v'],
      (
        'youtube.com' || 'youtube-nocookie.com',
        ['embed' || 'shorts' || 'live' || 'v', final id, ...],
      ) =>
        id,
      _ => null,
    };
    return id != null && _idPattern.hasMatch(id) ? id : null;
  }

  static final _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// The video id of an in-player related / end-screen video link, which
  /// should play in place rather than open externally.
  @visibleForTesting
  static String? relatedVideoId(Uri uri) {
    final feature = uri.queryParameters['feature'] ?? '';
    if (!feature.startsWith('emb_rel')) return null;
    return convertUrlToId(uri.toString());
  }

  /// Thumbnail URL for [videoId].
  static String getThumbnail({
    required String videoId,
    ThumbnailQuality quality = .standard,
    ThumbnailFormat format = .jpeg,
  }) => format.buildUrl(videoId, quality);

  // MARK: Lifecycle

  /// Releases the player. The controller cannot be used afterwards.
  void close() {
    if (_closed) return;
    _closed = true;
    _pendingCalls.clear();
    if (_autoPlaying == this) _autoPlaying = null;
    if (!_ready.isCompleted) {
      _ready.future.ignore();
      _ready.completeError(const _Closed());
    }
    if (!_hostCompleter.isCompleted) {
      _hostCompleter.future.ignore();
      _hostCompleter.completeError(const _Closed());
    }
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    _host?.dispose();
    unawaited(
      (
        _valueController.close(),
        _videoStateController.close(),
        _apiChangeController.close(),
      ).wait,
    );
  }
}

final class const _Closed() implements Exception;
