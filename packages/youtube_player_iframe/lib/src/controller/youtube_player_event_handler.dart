import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Handles all the player events received from the player iframe.
class YoutubePlayerEventHandler {
  /// Creates [YoutubePlayerEventHandler] with the provided [controller].
  YoutubePlayerEventHandler(this.controller) {
    _events = {
      'Ready': onReady,
      'StateChange': onStateChange,
      'PlaybackQualityChange': onPlaybackQualityChange,
      'PlaybackRateChange': onPlaybackRateChange,
      'PlayerError': onError,
      'FullscreenButtonPressed': onFullscreenButtonPressed,
      'VideoState': onVideoState,
      'AutoplayBlocked': onAutoplayBlocked,
    };
  }

  /// The [YoutubePlayerController].
  final YoutubePlayerController controller;

  /// The [YoutubeVideoState] stream controller.
  final StreamController<YoutubeVideoState> videoStateController =
      StreamController.broadcast();

  final Completer<void> _readyCompleter = Completer();
  late final Map<String, ValueChanged<Object>> _events;

  /// Handles the [javaScriptMessage] from the player iframe and create events.
  void call(JavaScriptMessage javaScriptMessage) {
    final data = Map.from(jsonDecode(javaScriptMessage.message));
    if (data['playerId'] != controller.playerId) return;

    for (final entry in data.entries) {
      if (entry.key == 'ApiChange') {
        onApiChange(entry.value);
      } else {
        _events[entry.key]?.call(entry.value ?? Object());
      }
    }
  }

  /// This event fires whenever a player has finished loading and is ready to begin receiving API calls.
  /// Your application should implement this function if you want to automatically execute certain operations,
  /// such as playing the video or displaying information about the video, as soon as the player is ready.
  void onReady(Object data) {
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  /// This event fires whenever the player's state changes.
  /// The data property of the event object that the API passes to your event listener function
  /// will specify an integer that corresponds to the new player state.
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

  /// This event fires whenever the video playback quality changes.
  /// It might signal a change in the viewer's playback environment.
  /// See the [YouTube Help Center](https://support.google.com/youtube/answer/91449)
  /// for more information about factors that affect playback conditions or that might cause the event to fire.
  void onPlaybackQualityChange(Object data) {
    controller.update(playbackQuality: data as String);
  }

  /// This event fires whenever the video playback rate changes.
  /// For example, if you call the [YoutubePlayerController.setPlaybackRate] function,
  /// this event will fire if the playback rate actually changes.
  /// Your application should respond to the event and should not assume
  /// that the playback rate will automatically change when the [YoutubePlayerController.setPlaybackRate] function is called.
  ///
  /// Similarly, your code should not assume that the video playback rate will only change
  /// as a result of an explicit call to [YoutubePlayerController.setPlaybackRate].
  void onPlaybackRateChange(Object data) {
    controller.update(playbackRate: (data as num).toDouble());
  }

  /// This event is fired to indicate that the player has loaded (or unloaded) a module with exposed API methods.
  /// Your application can listen for this event and then poll the player to determine
  /// which options are exposed for the recently loaded module.
  /// Your application can then retrieve or update the existing settings for those options.
  void onApiChange(Object? data) {}

  /// This event is fired to indicate that the fullscreen button was clicked.
  void onFullscreenButtonPressed(Object data) {
    controller.toggleFullScreen();
  }

  /// This event fires if an error occurs in the player.
  /// The API will pass an event object to the event listener function.
  /// That [data] property will specify an integer that identifies the type of error that occurred.
  void onError(Object data) {
    final error = YoutubeError.values.firstWhere(
      (error) => error.code == data,
      orElse: () => YoutubeError.unknown,
    );

    controller.update(error: error);
  }

  /// This event fires when the player receives information about video states.
  void onVideoState(Object data) {
    if (videoStateController.isClosed) return;

    videoStateController.add(YoutubeVideoState.fromJson(data.toString()));
  }

  /// This event fires when the auto playback is blocked by the browser.
  void onAutoplayBlocked(Object data) {
    log(
      'Autoplay was blocked by browser. '
      'Most modern browser does not allow video with sound to autoplay. '
      'Try muting the video to autoplay.',
    );
  }

  /// Returns a [Future] that completes when the player is ready.
  Future<void> get isReady => _readyCompleter.future;
}
