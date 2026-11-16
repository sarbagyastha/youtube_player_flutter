// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

import 'iframe_api.dart';
import 'params.dart';
import 'value.dart';

/// Decides what happens when the user taps a link that leaves the player
/// (title, channel, logo, share, related video). Return `true` when handled;
/// otherwise related videos load in-player and other links open externally.
typedef LinkTapHandler = FutureOr<bool> Function(Uri uri);

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

  /// Optional handler for links that leave the player.
  final LinkTapHandler? onLinkTap,

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
    LinkTapHandler? onLinkTap,
  }) {
    final controller = YoutubePlayerController(
      params: params,
      onLoadError: onLoadError,
      onLinkTap: onLinkTap,
      key: videoId,
    ).._initialVideoId = videoId;
    if (startSeconds != null || endSeconds != null) {
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

  final _valueController = StreamController<YoutubePlayerValue>.broadcast();
  final _videoStateController = StreamController<YoutubeVideoState>.broadcast();
  final _apiChangeController = StreamController<void>.broadcast();
  final _ready = Completer<YoutubePlayerHost>();
  final _hostCompleter = Completer<YoutubePlayerHost>();
  final _subscriptions = <StreamSubscription<Object?>>[];

  YoutubePlayerValue _value = const YoutubePlayerValue();
  ValueChanged<bool>? _fullScreenListener;
  YoutubePlayerHost? _host;
  var _closed = false;
  var _autoPlayPending = false;

  // Cached by events, so the common getters never round-trip.
  var _currentTime = 0.0;
  var _loadedFraction = 0.0;
  var _duration = 0.0;
  var _volume = 100;
  var _muted = false;
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
          videoId: initialVideoId,
          customControls: customControls,
        ),
      );
      if (_closed) {
        await host.dispose();
        return;
      }
      _host = host;
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
        if (!_ready.isCompleted) _ready.complete(_host);
      case StateChangeEvent(:final state, :final videoData, :final duration):
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
            playbackRate: freshVideo ? 1 : null,
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
        _volume = event.volume;
        _muted = event.muted;
        _videoStateController.add(
          YoutubeVideoState(
            position: _toDuration(event.currentTime),
            loadedFraction: event.loadedFraction,
          ),
        );
        if (event.duration > 0 && event.duration != _duration) {
          _duration = event.duration;
          _emit(
            _value.copyWith(
              metaData: _value.metaData.copyWith(
                duration: _toDuration(event.duration),
              ),
            ),
          );
        }
    }
  }

  Future<void> _onNavigation(Uri uri) async {
    if (onLinkTap case final handler? when await handler(uri)) return;
    if (relatedVideoId(uri) case final videoId?) {
      return loadVideoById(videoId: videoId);
    }
    await launchUrl(uri, mode: .externalApplication);
  }

  void _onFullscreen(bool isFullScreen) {
    _emit(_value.copyWith(isFullScreen: isFullScreen));
    _fullScreenListener?.call(isFullScreen);
  }

  // MARK: Command plumbing

  /// Runs [method] once the player is ready. Calls keep their order.
  Future<void> _run(
    PlayerMethod method, [
    List<Object?> args = const [],
  ]) async {
    if (_closed) return;
    try {
      final host = await _ready.future;
      await host.call(method, args);
    } on _Closed {
      return;
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
      unawaited(previous.pauseVideo());
    }
    _autoPlaying = this;
    unawaited(playVideo());
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
  Future<void> cueVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  }) => _run(.cueVideoById, [
    _video('videoId', videoId, startSeconds, endSeconds),
  ]);

  @override
  Future<void> loadVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  }) => _run(.loadVideoById, [
    _video('videoId', videoId, startSeconds, endSeconds),
  ]);

  @override
  Future<void> cueVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  }) => _run(.cueVideoByUrl, [
    _video('mediaContentUrl', mediaContentUrl, startSeconds, endSeconds),
  ]);

  @override
  Future<void> loadVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  }) => _run(.loadVideoByUrl, [
    _video('mediaContentUrl', mediaContentUrl, startSeconds, endSeconds),
  ]);

  @override
  Future<void> cuePlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  }) => _run(.cuePlaylist, _list(list, listType, index, startSeconds));

  @override
  Future<void> loadPlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  }) => _run(.loadPlaylist, _list(list, listType, index, startSeconds));

  /// Loads the video in any common YouTube [url] form (watch, youtu.be,
  /// embed, shorts, live).
  Future<void> loadVideo(String url) {
    final videoId = convertUrlToId(url);
    assert(videoId != null, 'No YouTube video id in $url');
    return videoId == null ? Future.value() : loadVideoById(videoId: videoId);
  }

  // MARK: Playback

  @override
  Future<void> playVideo() => _run(.playVideo);

  @override
  Future<void> pauseVideo() => _run(.pauseVideo);

  @override
  Future<void> stopVideo() => _run(.stopVideo);

  @override
  Future<void> seekTo({required double seconds, bool allowSeekAhead = false}) =>
      _run(.seekTo, [seconds, allowSeekAhead]);

  @override
  Future<void> nextVideo() => _run(.nextVideo);

  @override
  Future<void> previousVideo() => _run(.previousVideo);

  @override
  Future<void> playVideoAt(int index) => _run(.playVideoAt, [index]);

  // MARK: Volume

  @override
  Future<void> mute() => _run(.mute);

  @override
  Future<void> unMute() => _run(.unMute);

  @override
  Future<bool> get isMuted async => _muted;

  @override
  Future<void> setVolume(int volume) {
    assert(volume >= 0 && volume <= 100, 'Volume must be within 0..100');
    return _run(.setVolume, [volume.clamp(0, 100)]);
  }

  @override
  Future<int> get volume async => _volume;

  // MARK: Size, rate, playlist behaviour

  @override
  Future<void> setSize(double width, double height) =>
      _run(.setSize, [width, height]);

  @override
  Future<double> get playbackRate async => _value.playbackRate;

  @override
  Future<void> setPlaybackRate(double suggestedRate) =>
      _run(.setPlaybackRate, [suggestedRate]);

  @override
  Future<List<double>> get availablePlaybackRates async =>
      switch (await _query(.getAvailablePlaybackRates)) {
        final List<Object?> rates => [for (final r in rates) _toDouble(r)],
        _ => const [1],
      };

  @override
  Future<void> setLoop({required bool loopPlaylists}) =>
      _run(.setLoop, [loopPlaylists]);

  @override
  Future<void> setShuffle({required bool shufflePlaylists}) =>
      _run(.setShuffle, [shufflePlaylists]);

  // MARK: Status and information

  @override
  Future<PlayerState> get playerState async => _value.playerState;

  @override
  Future<double> get currentTime async => _currentTime;

  @override
  Future<double> get videoLoadedFraction async => _loadedFraction;

  @override
  Future<double> get duration async => _duration;

  @override
  Future<VideoData> get videoData async => _videoData;

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
  Future<void> setCaptionsFontSize(int size) =>
      _run(.setOption, ['captions', 'fontSize', size]);

  @override
  Future<void> reloadCaptions() =>
      _run(.setOption, ['captions', 'reload', true]);

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
  Future<void> setSphericalProperties(SphericalProperties properties) =>
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
  Future<void> exitFullScreen() async {
    final host = _host;
    if (host != null && !_closed) await host.exitFullscreen();
  }

  /// Toggles fullscreen; see [enterFullScreen].
  Future<void> toggleFullScreen() =>
      _value.isFullScreen ? exitFullScreen() : enterFullScreen();

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
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (_autoPlaying == this) _autoPlaying = null;
    if (!_ready.isCompleted) {
      _ready.future.ignore();
      _ready.completeError(const _Closed());
    }
    if (!_hostCompleter.isCompleted) {
      _hostCompleter.future.ignore();
      _hostCompleter.completeError(const _Closed());
    }
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _host?.dispose();
    await (
      _valueController.close(),
      _videoStateController.close(),
      _apiChangeController.close(),
    ).wait;
  }
}

final class const _Closed() implements Exception;
