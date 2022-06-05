import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/src/iframe_api/src/functions/playback_status.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'youtube_player_controller.dart';

class YoutubePlayerEventHandler {
  ///
  YoutubePlayerEventHandler(this.controller) {
    final _events = <String, void Function(Object)>{
      'Ready': onReady,
      'StateChange': onStateChange,
      'PlaybackQualityChange': onPlaybackQualityChange,
      'PlaybackRateChange': onPlaybackRateChange,
      'ApiChange': onApiChange,
      'PlayerError': onError,
    };

    javascriptChannels = {
      JavascriptChannel(
        name: 'YoutubePlayer',
        onMessageReceived: (channel) {
          final data = Map.from(jsonDecode(channel.message));
          for (final entry in data.entries) {
            _events[entry.key]?.call(entry.value);
          }
        },
      ),
    };
  }

  final YoutubePlayerController controller;
  late final Set<JavascriptChannel> javascriptChannels;

  final Completer<void> _readyCompleter = Completer();

  void onReady(Object data) {
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  void onStateChange(Object data) {
    final stateCode = data as int;

    final playerState = PlayerState.values.firstWhere(
      (state) => state.code == stateCode,
      orElse: () => PlayerState.unknown,
    );

    if (playerState == PlayerState.playing) {
      controller.update(playerState: playerState, error: YoutubeError.none);
    } else {
      controller.update(playerState: playerState);
    }
  }

  void onPlaybackQualityChange(Object data) {
    controller.update(playbackQuality: data as String);
  }

  void onPlaybackRateChange(Object data) {
    // TODO: implement onPlaybackRateChange
  }

  void onApiChange(Object data) {
    // TODO: implement onApiChange
  }

  void onError(Object data) {
    // TODO: implement onError
  }

  Future<void> get isReady => _readyCompleter.future;
}
