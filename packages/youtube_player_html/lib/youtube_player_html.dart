// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// The web implementation of `youtube_player`.
///
/// **You don't depend on this package directly.** Add `youtube_player` to your
/// app; it includes this package and uses it automatically on the web.
///
/// The player is a regular YouTube IFrame embed placed in your page. Works
/// with both the JavaScript and the `--wasm` builds.
///
/// Because the player iframe is cross-origin, the page cannot reach into it:
/// hiding player elements and intercepting clicks are not available, and links
/// open in a new tab. If your page is cross-origin isolated (COOP/COEP
/// headers, e.g. for multithreaded Wasm), set
/// `YoutubePlayerParams(webCredentialless: true)`.
///
/// ## Requirements
///
/// * Dart 3.14 or newer
/// * Flutter 3.50 or newer
///
/// See the `youtube_player` package for the player API.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

import 'src/bindings.dart';

const _viewType = 'np.com.sarbagyastha.youtube_player/web';

/// Hosts players as IFrame API iframes directly in the page.
final class WebYoutubePlayer extends YoutubePlayerPlatform {
  /// Registers this implementation. Called by the plugin registrant.
  static void registerWith(Registrar registrar) {
    YoutubePlayerPlatform.instance = WebYoutubePlayer();
  }

  static final _hosts = <int, _WebHost>{};
  static var _nextId = 0;
  static var _factoryRegistered = false;

  static void _registerFactory() {
    if (_factoryRegistered) return;
    _factoryRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (
      int _, {
      Object? params,
    }) {
      final id = (params as Map<Object?, Object?>?)?['id'];
      return _hosts[id]?._container ?? web.HTMLDivElement();
    });
  }

  @override
  Future<YoutubePlayerHost> createHost(YoutubeHostParams params) async {
    _registerFactory();
    final id = _nextId++;
    final host = _hosts[id] = _WebHost(id, params);
    try {
      await loadIframeApi();
      host._start();
    } on Object catch (error) {
      host._fail('$error');
    }
    return host;
  }
}

final class _WebHost(final int _id, final YoutubeHostParams _params)
    implements YoutubePlayerHost {
  this {
    final origin = web.window.location.origin;
    _vars = {
      for (final MapEntry(:key, :value) in _params.playerVars.entries)
        key: '$value',
      'enablejsapi': '1',
      'origin': '${_params.playerVars['origin'] ?? origin}',
      'widget_referrer': '${_params.playerVars['widget_referrer'] ?? origin}',
    };
    _iframe = web.HTMLIFrameElement()
      ..allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen'
      ..allowFullscreen = true
      ..referrerPolicy = 'strict-origin-when-cross-origin'
      ..title = 'YouTube video player';
    // Must be set before the iframe loads; required on cross-origin
    // isolated pages (COEP), e.g. multithreaded Wasm builds.
    if (_params.webCredentialless) _iframe.setAttribute('credentialless', '');
    _iframe.style
      ..border = 'none'
      ..width = '100%'
      ..height = '100%'
      ..display = 'block'
      ..pointerEvents = _params.pointerEvents;
    _container = web.HTMLDivElement()..append(_iframe);
    _container.style
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = _css(
        _params.backgroundColor ?? const Color(0xFF000000),
      );
    _fullscreenListener = _onFullscreenChange.toJS;
    web.document.addEventListener('fullscreenchange', _fullscreenListener);
  }

  late final Map<String, String> _vars;
  late final web.HTMLIFrameElement _iframe;
  late final web.HTMLDivElement _container;
  late final JSFunction _fullscreenListener;
  YTPlayer? _player;
  Timer? _ticker;
  TickEvent? _lastTick;
  bool? _isFullscreen;
  var _ready = false;
  var _disposed = false;

  /// Calls received before the player is ready, replayed in order.
  final _pending = <(PlayerMethod, List<Object?>, Completer<Object?>?)>[];

  final _events = StreamController<PlayerEvent>.broadcast();
  final _fullscreen = StreamController<bool>.broadcast();

  @override
  Stream<PlayerEvent> get events => _events.stream;

  // Links inside the iframe open in new tabs natively on the web; the
  // cross-origin iframe can't be observed or changed.
  @override
  Stream<NavigationRequest> get navigations => const Stream.empty();

  @override
  bool get supportsElementControl => false;

  @override
  void setHiddenElements(Set<PlayerElement> elements) {}

  @override
  void resolveClick(int clickId, {required bool allow}) {}

  @override
  Stream<bool> get fullscreenChanges => _fullscreen.stream;

  void _emit(PlayerEvent event) {
    if (!_disposed) _events.add(event);
  }

  void _fail(String description) =>
      _emit(LoadErrorEvent(YoutubeLoadError(description: description)));

  /// Starts the player once the API is loaded.
  ///
  /// Without an initial video the IFrame API never fires `onReady`, so the
  /// host reports ready right away and creates the player from the first
  /// queueing call instead (see [_createFor]).
  void _start() {
    if (_params.videoId case final videoId?) {
      _attachPlayer(videoId: videoId);
    } else {
      _emit(const ReadyEvent());
    }
  }

  static const _queueing = {
    PlayerMethod.cueVideoById,
    PlayerMethod.loadVideoById,
    PlayerMethod.cueVideoByUrl,
    PlayerMethod.loadVideoByUrl,
    PlayerMethod.cuePlaylist,
    PlayerMethod.loadPlaylist,
  };

  void _createFor(PlayerMethod method, List<Object?> args) {
    final extra = <String, String>{};
    final videoId = switch (args) {
      [final List<Object?> ids, ...] when ids.isNotEmpty => switch (args
          .elementAtOrNull(1)) {
        final num i when i >= 0 && i < ids.length => ids[i.toInt()],
        _ => ids.first,
      } as String?,
      [{'videoId': final String id}, ...] => id,
      [{'mediaContentUrl': final String url}, ...] => RegExp(
        r'/(?:v|embed)/([\w-]{11})',
      ).firstMatch(url)?.group(1),
      [{'list': final String list}, ...] => () {
        extra['listType'] = '${(args.first! as Map)['listType'] ?? 'playlist'}';
        extra['list'] = list;
        return null;
      }(),
      _ => null,
    };
    _attachPlayer(videoId: videoId, extraVars: extra);
  }

  void _attachPlayer({
    String? videoId,
    Map<String, String> extraVars = const {},
  }) {
    _iframe.src =
        '${_params.host}/embed/${videoId ?? ''}'
        '?${Uri(queryParameters: {..._vars, ...extraVars}).query}';
    // Callbacks are converted once and reused for the player's lifetime.
    _player = YTPlayer(
      _iframe,
      YTPlayerOptions(
        events: YTEvents(
          onReady: (YTEvent _) {
            _ready = true;
            if (_params.videoId != null) _emit(const ReadyEvent());
            _flush();
          }.toJS,
          onStateChange: _onStateChange.toJS,
          onPlaybackRateChange: (YTEvent e) {
            if (_number(e.data) case final rate?) {
              _emit(PlaybackRateChangeEvent(rate));
            }
          }.toJS,
          onPlaybackQualityChange: (YTEvent e) {
            final data = e.data;
            if (data != null && data.isA<JSString>()) {
              _emit(PlaybackQualityChangeEvent((data as JSString).toDart));
            }
          }.toJS,
          onError: (YTEvent e) {
            if (_number(e.data) case final code?) {
              _emit(ErrorEvent(.fromCode(code.toInt())));
            }
          }.toJS,
          onApiChange: (YTEvent _) {
            _emit(const ApiChangeEvent());
          }.toJS,
          onAutoplayBlocked: (YTEvent _) {
            _emit(const AutoplayBlockedEvent());
          }.toJS,
        ),
      ),
    );
  }

  void _onStateChange(YTEvent e) {
    final player = _player;
    final code = _number(e.data);
    if (player == null || code == null) return;
    final state = PlayerState.fromCode(code.toInt());
    VideoData? videoData;
    double? duration;
    if (state == .unStarted || state == .playing || state == .cued) {
      if (player.getVideoData() case final data?) {
        videoData = VideoData(
          videoId: data.videoId ?? '',
          title: data.title ?? '',
          author: data.author ?? '',
        );
      }
      duration = player.getDuration();
    }
    _emit(
      StateChangeEvent(
        state,
        videoData: videoData,
        duration: duration,
        playbackRate: player.getPlaybackRate(),
      ),
    );
    if (state.isActive) {
      _ticker ??= Timer.periodic(_params.tickInterval, (_) => _tick());
    } else if (_ticker != null) {
      _ticker!.cancel();
      _ticker = null;
      _settle(const [0, 250]);
    }
  }

  void _tick() {
    final player = _player;
    if (player == null || !_ready) return;
    final tick = TickEvent(
      currentTime: player.getCurrentTime(),
      loadedFraction: player.getVideoLoadedFraction(),
      duration: player.getDuration(),
      volume: player.getVolume(),
      muted: player.isMuted(),
    );
    if (_lastTick case final last?
        when last.currentTime == tick.currentTime &&
            last.loadedFraction == tick.loadedFraction &&
            last.duration == tick.duration &&
            last.volume == tick.volume &&
            last.muted == tick.muted) {
      return;
    }
    _lastTick = tick;
    _emit(tick);
  }

  /// Ticks after each of [delaysMs]; unchanged ticks are dropped.
  void _settle(List<int> delaysMs) {
    for (final ms in delaysMs) {
      Timer(Duration(milliseconds: ms), _tick);
    }
  }

  void _onFullscreenChange(web.Event _) {
    if (_disposed) return;
    final element = web.document.fullscreenElement;
    final isFullscreen = element == _iframe || element == _container;
    // Every player hears every change; report only our own transitions.
    if (isFullscreen == (_isFullscreen ?? false)) return;
    _isFullscreen = isFullscreen;
    _fullscreen.add(isFullscreen);
  }

  JSAny? _invoke(PlayerMethod method, List<Object?> args) =>
      _player?.callMethodVarArgs<JSAny?>(method.name.toJS, [
        for (final a in args) a.jsify(),
      ]);

  void _flush() {
    for (final (method, args, completer) in _pending.toList()) {
      if (completer == null) {
        call(method, args);
      } else {
        completer.complete(query(method, args));
      }
    }
    _pending.clear();
  }

  /// Buffers a call made before the player is ready; returns whether it was.
  bool _buffer(
    PlayerMethod method,
    List<Object?> args, [
    Completer<Object?>? c,
  ]) {
    if (_ready) return false;
    _pending.add((method, args, c));
    if (_player == null && _queueing.contains(method)) _createFor(method, args);
    return true;
  }

  @override
  void call(PlayerMethod method, [List<Object?> args = const []]) {
    // Frame helpers only exist on native hosts.
    if (_disposed) return;
    if (method case .setHidden || .resolveClick) return;
    if (method != .exitFullscreen &&
        method != .requestFullscreen &&
        _buffer(method, args)) {
      return;
    }
    switch (method) {
      case .exitFullscreen:
        exitFullscreen();
      case .requestFullscreen:
        unawaited(query(method));
      default:
        _invoke(method, args);
        if (method case .seekTo || .setVolume || .mute || .unMute
            when _ticker == null) {
          // The IFrame API getters update asynchronously.
          _settle(const [50, 250, 1000]);
        }
    }
  }

  @override
  Future<Object?> query(
    PlayerMethod method, [
    List<Object?> args = const [],
  ]) async {
    if (_disposed) return null;
    if (method != .requestFullscreen && !_ready) {
      final completer = Completer<Object?>();
      _buffer(method, args, completer);
      return completer.future;
    }
    if (method == .requestFullscreen) {
      try {
        await _container.requestFullscreen().toDart;
        return true;
      } on Object {
        return false;
      }
    }
    return _invoke(method, args).dartify();
  }

  @override
  void setBackgroundColor(Color color) {
    _container.style.backgroundColor = _css(color);
  }

  @override
  void exitFullscreen() {
    if (web.document.fullscreenElement != null) {
      web.document.exitFullscreen().toDart.ignore();
    }
  }

  @override
  Widget buildView({
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = const {},
  }) => HtmlElementView(viewType: _viewType, creationParams: {'id': _id});

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WebYoutubePlayer._hosts.remove(_id);
    _ticker?.cancel();
    for (final (_, _, completer) in _pending) {
      completer?.complete(null);
    }
    _pending.clear();
    web.document.removeEventListener('fullscreenchange', _fullscreenListener);
    _player?.destroy();
    _container.remove();
    unawaited((_events.close(), _fullscreen.close()).wait);
  }

  static double? _number(JSAny? value) => value != null && value.isA<JSNumber>()
      ? (value as JSNumber).toDartDouble
      : null;

  static String _css(Color c) =>
      'rgba(${(c.r * 255).round()}, ${(c.g * 255).round()}, '
      '${(c.b * 255).round()}, ${c.a})';
}
