import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

import 'youtube_player_controller.dart';

class YoutubePlayerEventHandler {
  YoutubePlayerEventHandler(this.controller) {
    javascriptChannels = {
      JavascriptChannel(name: 'Ready', onMessageReceived: onReady),
      JavascriptChannel(name: 'StateChange', onMessageReceived: onStateChange),
      JavascriptChannel(name: 'ApiChange', onMessageReceived: onApiChange),
      JavascriptChannel(name: 'PlayerError', onMessageReceived: onError),
      JavascriptChannel(
        name: 'PlaybackQualityChange',
        onMessageReceived: onPlaybackQualityChange,
      ),
      JavascriptChannel(
        name: 'PlaybackRateChange',
        onMessageReceived: onPlaybackRateChange,
      ),
    };
  }

  final YoutubePlayerController controller;
  late final Set<JavascriptChannel> javascriptChannels;

  final Completer<void> _readyCompleter = Completer();

  void onReady(JavascriptMessage data) {
    _readyCompleter.complete();
  }

  void onStateChange(JavascriptMessage data) {
    // TODO: implement onStateChange
  }

  void onPlaybackQualityChange(JavascriptMessage data) {
    // TODO: implement onPlaybackQualityChange
  }

  void onPlaybackRateChange(JavascriptMessage data) {
    // TODO: implement onPlaybackRateChange
  }

  void onApiChange(JavascriptMessage data) {
    // TODO: implement onApiChange
  }

  void onError(JavascriptMessage data) {
    // TODO: implement onError
  }

  Future<void> get isReady => _readyCompleter.future;
}
