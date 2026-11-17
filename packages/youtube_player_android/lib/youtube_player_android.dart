// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// The Android implementation of `youtube_player`.
///
/// **You don't depend on this package directly.** Add `youtube_player` to your
/// app; it includes this package and uses it automatically on Android.
///
/// Each player runs in an Android `WebView` that shows the YouTube IFrame
/// player, and fullscreen uses a native fullscreen view
/// ([YoutubeHostParams.fullscreenOrientation] controls rotation). Hiding player
/// elements and intercepting clicks are supported.
///
/// The plugin declares the `INTERNET` permission, so no manifest changes are
/// required. For the best rendering on API 34+ devices with Vulkan, you can opt
/// in to
/// [Hybrid Composition++](https://docs.flutter.dev/platform-integration/android/platform-views#hcpp)
/// by adding this inside `<application>` in `AndroidManifest.xml`; devices
/// without support fall back automatically:
///
/// ```xml
/// <meta-data
///     android:name="io.flutter.embedding.android.EnableHcpp"
///     android:value="true" />
/// ```
///
/// ## Requirements
///
/// * Dart 3.14 or newer
/// * Flutter 3.50 or newer
///
/// See the `youtube_player` package for the player API.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

import 'src/messages.g.dart';

const _viewType = 'np.com.sarbagyastha.youtube_player/webview';

/// Hosts players in Android WebViews.
///
/// Talks to the native side through Pigeon Native Interop (JNI): host calls
/// are direct synchronous calls, with no platform channel in between.
final class AndroidYoutubePlayer({
  /// Host API override for tests.
  @visibleForTesting YoutubeHostApiForNativeInterop? api,
}) extends YoutubePlayerPlatform {
  /// Creates the Android implementation.
  this;

  /// Registers this implementation. Called by the plugin registrant.
  static void registerWith() {
    YoutubePlayerPlatform.instance = AndroidYoutubePlayer();
  }

  final YoutubeHostApiForNativeInterop? _apiOverride = api;

  // Resolved lazily: `registerWith` runs before JNI is initialized.
  late final YoutubeHostApiForNativeInterop _api =
      _apiOverride ??
      YoutubeHostApiForNativeInterop.getInstance() ??
      (throw StateError('youtube_player_android is not registered natively'));
  late final _receiver = _Receiver(this);
  final _hosts = <int, _AndroidHost>{};

  /// Whether Hybrid Composition++ is available (API 34+, Vulkan, app opt-in).
  bool? _hcpp;

  @override
  Future<YoutubePlayerHost> createHost(YoutubeHostParams params) async {
    _receiver.listen();
    _hcpp ??= await _checkHcpp();
    final info = _api.create(
      NativeHostConfig(
        appId: params.appId,
        userAgent: params.userAgent,
        debuggable: params.debuggable,
        backgroundColor: params.backgroundColor?.toARGB32(),
        fullscreenOrientation: .values.byName(
          params.fullscreenOrientation.name,
        ),
        frameScript: buildFrameScript(
          hidden: params.hiddenElements,
          customElements: params.customElements,
          interceptButtons: params.interceptButtons,
        ),
      ),
      buildPlayerPage(params),
    );
    return _hosts[info.handle] = _AndroidHost(
      this,
      info.handle,
      supportsElementControl: info.frameScripting,
    );
  }

  @override
  bool openExternal(Uri uri) => _api.openExternal(uri.toString());

  static Future<bool> _checkHcpp() async {
    try {
      return await HybridAndroidViewController.checkIfSupported();
    } on Object {
      return false;
    }
  }
}

final class _Receiver(final AndroidYoutubePlayer _platform)
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

  _AndroidHost? _host(int handle) => _platform._hosts[handle];

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

final class _AndroidHost(
  final AndroidYoutubePlayer _platform,
  final int _handle, {
  @override required final bool supportsElementControl,
}) extends BridgeHost {
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
    if (_platform._hcpp != true) {
      // Texture Layer Hybrid Composition, falling back to Hybrid Composition.
      return AndroidView(
        viewType: _viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: gestureRecognizers,
      );
    }
    // Hybrid Composition++: the WebView keeps its own surface, composited by
    // SurfaceFlinger in sync with Flutter's frames.
    return PlatformViewLink(
      viewType: _viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: gestureRecognizers,
        hitTestBehavior: .opaque,
      ),
      onCreatePlatformView: (params) =>
          PlatformViewsService.initHybridAndroidView(
              id: params.id,
              viewType: _viewType,
              layoutDirection: .ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () => params.onFocusChanged(true),
            )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create(),
    );
  }
}
