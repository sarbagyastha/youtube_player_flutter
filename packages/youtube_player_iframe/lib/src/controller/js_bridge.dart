import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

/// Wraps [WebViewController] JS execution with player-readiness guards.
///
/// This class is package-internal and is not exported from the barrel.
class JsBridge {
  JsBridge({
    required this.webViewController,
    required Future<void> Function() isReady,
  }) : _isReady = isReady;

  final WebViewController webViewController;
  final Future<void> Function() _isReady;
  final Completer<void> _initCompleter = Completer();

  /// Signals that the player HTML has been loaded into the WebView.
  void completeInit() {
    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  /// Whether [completeInit] has been called.
  bool get isInitCompleted => _initCompleter.isCompleted;

  Future<void> _waitReady() {
    return _isReady().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException(
        'YouTube player failed to initialize within 30 seconds.',
      ),
    );
  }

  Future<String> _prepareData(Map<String, dynamic>? data) async {
    await _waitReady();
    return data == null ? '' : jsonEncode(data);
  }

  /// Calls a player method with optional JSON-encoded [data].
  Future<void> run(String functionName, {Map<String, dynamic>? data}) async {
    await _initCompleter.future;
    final varArgs = await _prepareData(data);
    return webViewController.runJavaScript('player.$functionName($varArgs);');
  }

  /// Calls a player method and returns the result as a string.
  Future<String> runWithResult(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    await _initCompleter.future;
    final varArgs = await _prepareData(data);
    try {
      final result = await webViewController.runJavaScriptReturningResult(
        'player.$functionName($varArgs);',
      );
      return result.toString();
    } catch (_) {
      return '';
    }
  }

  /// Evaluates arbitrary [javascript] after the player is ready.
  Future<void> eval(String javascript) async {
    await _waitReady();
    return webViewController.runJavaScript(javascript);
  }

  /// Evaluates arbitrary [javascript] and returns the result as a string.
  Future<String> evalWithResult(String javascript) async {
    await _waitReady();
    final result = await webViewController.runJavaScriptReturningResult(
      javascript,
    );
    return result.toString();
  }
}
