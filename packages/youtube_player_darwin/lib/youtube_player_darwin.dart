// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// iOS and macOS implementation of youtube_player.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

import 'src/messages.g.dart';

const _viewType = 'np.com.sarbagyastha.youtube_player/webview';

/// Hosts players in WKWebViews.
///
/// Talks to the native side through Pigeon Native Interop (FFI): host calls
/// are direct synchronous calls, with no platform channel in between.
final class DarwinYoutubePlayer({
  /// Host API override for tests.
  @visibleForTesting YoutubeHostApiForNativeInterop? api,
}) extends YoutubePlayerPlatform {
  /// Registers this implementation. Called by the plugin registrant.
  static void registerWith() {
    YoutubePlayerPlatform.instance = DarwinYoutubePlayer();
  }

  final YoutubeHostApiForNativeInterop? _apiOverride = api;

  // Resolved lazily, after the native plugin has registered.
  late final YoutubeHostApiForNativeInterop _api =
      _apiOverride ??
      YoutubeHostApiForNativeInterop.getInstance() ??
      (throw StateError('youtube_player_darwin is not registered natively'));
  late final _receiver = _Receiver(this);
  final _hosts = <int, _DarwinHost>{};

  @override
  Future<YoutubePlayerHost> createHost(YoutubeHostParams params) async {
    _receiver.listen();
    final info = _api.create(
      NativeHostConfig(
        appId: params.appId,
        userAgent: params.userAgent,
        debuggable: params.debuggable,
        backgroundColor: params.backgroundColor?.toARGB32(),
      ),
      buildPlayerPage(params),
    );
    return _hosts[info.handle] = _DarwinHost(this, info.handle);
  }
}

final class _Receiver(final DarwinYoutubePlayer _platform)
    implements YoutubeFlutterApi {
  var _listening = false;

  void listen() {
    if (_listening) return;
    _listening = true;
    // Players left behind by a previous isolate (hot restart) would keep
    // playing with nobody listening.
    _platform._api.reset();
    YoutubeFlutterApiRegistrar().register(this);
  }

  _DarwinHost? _host(int handle) => _platform._hosts[handle];

  @override
  void onMessage(int handle, String json) => _host(handle)?.message(json);

  @override
  void onNavigation(int handle, String url) => _host(handle)?.navigation(url);

  @override
  void onLoadError(int handle, NativeLoadError error) => _host(handle)
      ?.loadError(
        YoutubeLoadError(
          code: error.code,
          description: error.message,
          url: error.url,
        ),
      );

  @override
  void onFullscreenChanged(int handle, bool isFullscreen) =>
      _host(handle)?.fullscreen(isFullscreen);
}

final class _DarwinHost(final DarwinYoutubePlayer _platform, final int _handle)
    extends BridgeHost {
  YoutubeHostApiForNativeInterop get _api => _platform._api;

  void message(String json) => receiveFromPage(json);
  void navigation(String url) => emitNavigation(url);
  void loadError(YoutubeLoadError error) => emitLoadError(error);
  void fullscreen(bool value) => emitFullscreen(value);

  @override
  void sendToPage(String json) => _api.send(_handle, json);

  @override
  void disposeNative() {
    _platform._hosts.remove(_handle);
    _api.dispose(_handle);
  }

  @override
  void setBackgroundColor(Color color) =>
      _api.setBackgroundColor(_handle, color.toARGB32());

  @override
  void exitFullscreen() => _api.exitFullscreen(_handle);

  @override
  Widget buildView({
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = const {},
  }) {
    final creationParams = {'handle': _handle};
    return switch (defaultTargetPlatform) {
      .macOS => AppKitView(
        viewType: _viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: gestureRecognizers,
      ),
      _ => UiKitView(
        viewType: _viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: gestureRecognizers,
      ),
    };
  }
}
