// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Web implementation of youtube_player.
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
      host._attachPlayer();
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
    final vars = {
      for (final MapEntry(:key, :value) in _params.playerVars.entries)
        key: '$value',
      'enablejsapi': '1',
      'origin': '${_params.playerVars['origin'] ?? origin}',
      'widget_referrer': '${_params.playerVars['widget_referrer'] ?? origin}',
    };
    _iframe = web.HTMLIFrameElement()
      ..src =
          '${_params.host}/embed/${_params.videoId ?? ''}'
          '?${Uri(queryParameters: vars).query}'
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

  late final web.HTMLIFrameElement _iframe;
  late final web.HTMLDivElement _container;
  late final JSFunction _fullscreenListener;
  YTPlayer? _player;
  Timer? _ticker;
  var _ready = false;
  var _disposed = false;

  final _events = StreamController<PlayerEvent>.broadcast();
  final _fullscreen = StreamController<bool>.broadcast();

  @override
  Stream<PlayerEvent> get events => _events.stream;

  // Links inside the iframe open in new tabs natively on the web.
  @override
  Stream<Uri> get navigations => const Stream.empty();

  @override
  Stream<bool> get fullscreenChanges => _fullscreen.stream;

  void _emit(PlayerEvent event) {
    if (!_disposed) _events.add(event);
  }

  void _fail(String description) =>
      _emit(LoadErrorEvent(YoutubeLoadError(description: description)));

  void _attachPlayer() {
    // Callbacks are converted once and reused for the player's lifetime.
    _player = YTPlayer(
      _iframe,
      YTPlayerOptions(
        events: YTEvents(
          onReady: (YTEvent _) {
            _ready = true;
            _emit(const ReadyEvent());
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
    _emit(StateChangeEvent(state, videoData: videoData, duration: duration));
    if (state.isActive) {
      _ticker ??= Timer.periodic(_params.tickInterval, (_) => _tick());
    } else {
      _ticker?.cancel();
      _ticker = null;
      _tick();
    }
  }

  void _tick() {
    final player = _player;
    if (player == null || !_ready) return;
    _emit(
      TickEvent(
        currentTime: player.getCurrentTime(),
        loadedFraction: player.getVideoLoadedFraction(),
        duration: player.getDuration(),
        volume: player.getVolume(),
        muted: player.isMuted(),
      ),
    );
  }

  void _onFullscreenChange(web.Event _) {
    final element = web.document.fullscreenElement;
    _fullscreen.add(element == _iframe || element == _container);
  }

  JSAny? _invoke(PlayerMethod method, List<Object?> args) =>
      _player?.callMethodVarArgs<JSAny?>(method.name.toJS, [
        for (final a in args) a.jsify(),
      ]);

  @override
  Future<void> call(
    PlayerMethod method, [
    List<Object?> args = const [],
  ]) async {
    if (_disposed || !_ready) return;
    switch (method) {
      case .exitFullscreen:
        await exitFullscreen();
      case .requestFullscreen:
        await query(method);
      default:
        _invoke(method, args);
        if (method case .seekTo || .setVolume || .mute || .unMute
            when _ticker == null) {
          Timer(const Duration(milliseconds: 50), _tick);
        }
    }
  }

  @override
  Future<Object?> query(
    PlayerMethod method, [
    List<Object?> args = const [],
  ]) async {
    if (_disposed || !_ready) return null;
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
  Future<void> setBackgroundColor(Color color) async {
    _container.style.backgroundColor = _css(color);
  }

  @override
  Future<void> exitFullscreen() async {
    if (web.document.fullscreenElement != null) {
      await web.document.exitFullscreen().toDart;
    }
  }

  @override
  Widget buildView({
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = const {},
  }) => HtmlElementView(viewType: _viewType, creationParams: {'id': _id});

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    WebYoutubePlayer._hosts.remove(_id);
    _ticker?.cancel();
    web.document.removeEventListener('fullscreenchange', _fullscreenListener);
    _player?.destroy();
    _container.remove();
    await (_events.close(), _fullscreen.close()).wait;
  }

  static double? _number(JSAny? value) => value != null && value.isA<JSNumber>()
      ? (value as JSNumber).toDartDouble
      : null;

  static String _css(Color c) =>
      'rgba(${(c.r * 255).round()}, ${(c.g * 255).round()}, '
      '${(c.b * 255).round()}, ${c.a})';
}
