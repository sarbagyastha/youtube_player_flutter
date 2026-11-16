// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'events.dart';
import 'types.dart';

/// One live player instance owned by a platform implementation.
///
/// A host is created (and starts loading) by
/// `YoutubePlayerPlatform.createHost`. It accepts calls immediately; callers
/// should wait for [ReadyEvent] before issuing IFrame API calls.
abstract interface class YoutubePlayerHost {
  /// Events from the player, in order.
  Stream<PlayerEvent> get events;

  /// Links the user tapped that would navigate away from the player (title,
  /// logo, related videos, share). The host already blocked the navigation.
  Stream<Uri> get navigations;

  /// System WebView / browser fullscreen transitions.
  Stream<bool> get fullscreenChanges;

  /// Calls [method] without waiting for a result.
  void call(PlayerMethod method, [List<Object?> args = const []]);

  /// Calls [method] and returns its JSON-compatible result.
  Future<Object?> query(PlayerMethod method, [List<Object?> args = const []]);

  /// Updates the color shown behind the player.
  void setBackgroundColor(Color color);

  /// Leaves system fullscreen if it is active.
  void exitFullscreen();

  /// Builds the widget that displays this player.
  Widget buildView({
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = const {},
  });

  /// Releases the player and its native view.
  void dispose();
}

/// Shared implementation for hosts that talk to the player page over a
/// string bridge (all native platforms).
///
/// Subclasses implement [sendToPage] and feed page messages to
/// [receiveFromPage]; this class handles encoding, request correlation and
/// event decoding.
abstract base class BridgeHost({
  /// How long [query] waits for a reply before failing.
  final Duration replyTimeout = const Duration(seconds: 10),
}) implements YoutubePlayerHost {
  final _events = StreamController<PlayerEvent>.broadcast();
  final _navigations = StreamController<Uri>.broadcast();
  final _fullscreen = StreamController<bool>.broadcast();
  final _pending = <int, Completer<Object?>>{};
  var _nextId = 0;
  var _disposed = false;

  /// Whether [dispose] was called.
  @protected
  bool get isDisposed => _disposed;

  @override
  Stream<PlayerEvent> get events => _events.stream;

  @override
  Stream<Uri> get navigations => _navigations.stream;

  @override
  Stream<bool> get fullscreenChanges => _fullscreen.stream;

  /// Delivers [json] to `window.__yp.recv` in the page.
  @protected
  void sendToPage(String json);

  /// Releases native resources. Called once from [dispose].
  @protected
  void disposeNative();

  @override
  void call(PlayerMethod method, [List<Object?> args = const []]) {
    if (_disposed) return;
    sendToPage(jsonEncode({'m': method.name, 'a': args}));
  }

  @override
  Future<Object?> query(
    PlayerMethod method, [
    List<Object?> args = const [],
  ]) async {
    if (_disposed) return null;
    final id = _nextId++;
    final completer = _pending[id] = Completer<Object?>();
    try {
      sendToPage(jsonEncode({'i': id, 'm': method.name, 'a': args}));
      return await completer.future.timeout(replyTimeout);
    } finally {
      _pending.remove(id);
    }
  }

  /// Handles one message posted by the page.
  @protected
  void receiveFromPage(String json) {
    if (_disposed) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return;
    }
    switch (decoded) {
      case {'r': final int id, 'x': final String error}:
        _pending[id]?.completeError(StateError(error));
      case {'r': final int id}:
        _pending[id]?.complete(decoded['v']);
      case {'e': final String name}:
        if (PlayerEvent.fromWire(name, decoded['d']) case final event?) {
          _events.add(event);
        }
    }
  }

  /// Reports a blocked navigation.
  @protected
  void emitNavigation(String url) {
    if (_disposed) return;
    if (Uri.tryParse(url) case final uri?) _navigations.add(uri);
  }

  /// Reports a fullscreen transition.
  @protected
  void emitFullscreen(bool isFullscreen) {
    if (!_disposed) _fullscreen.add(isFullscreen);
  }

  /// Reports a page load failure.
  @protected
  void emitLoadError(YoutubeLoadError error) {
    if (!_disposed) _events.add(LoadErrorEvent(error));
  }

  @override
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final completer in _pending.values) {
      completer.completeError(StateError('Player disposed'));
    }
    _pending.clear();
    disposeNative();
    unawaited(
      (_events.close(), _navigations.close(), _fullscreen.close()).wait,
    );
  }
}
