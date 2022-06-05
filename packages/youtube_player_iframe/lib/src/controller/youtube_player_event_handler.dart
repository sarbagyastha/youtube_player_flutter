import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';
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
      'PlayerError': onError,
    };

    javascriptChannels = {
      JavascriptChannel(
        name: 'YoutubePlayer',
        onMessageReceived: (channel) {
          final data = Map.from(jsonDecode(channel.message));

          for (final entry in data.entries) {
            if (entry.key == 'ApiChange') {
              onApiChange(entry.value);
            } else {
              _events[entry.key]?.call(entry.value);
            }
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

  Future<void> onStateChange(Object data) async {
    final stateCode = data as int;

    final playerState = PlayerState.values.firstWhere(
      (state) => state.code == stateCode,
      orElse: () => PlayerState.unknown,
    );

    if (playerState == PlayerState.playing) {
      controller.update(playerState: playerState, error: YoutubeError.none);

      final duration = await controller.duration;
      final videoData = await controller.videoData;

      final metaData = YoutubeMetaData(
        duration: Duration(milliseconds: (duration * 1000).truncate()),
        videoId: videoData.videoId,
        author: videoData.author,
        title: videoData.title,
      );

      controller.update(metaData: metaData);
    } else {
      controller.update(playerState: playerState);
    }
  }

  void onPlaybackQualityChange(Object data) {
    controller.update(playbackQuality: data as String);
  }

  void onPlaybackRateChange(Object data) {
    controller.update(playbackRate: (data as num).toDouble());
  }

  void onApiChange(Object? data) {
    print(data);
  }

  void onError(Object data) {
    final error = YoutubeError.values.firstWhere(
      (error) => error.code == data,
      orElse: () => YoutubeError.unknown,
    );

    controller.update(error: error);
  }

  Future<void> get isReady => _readyCompleter.future;
}
