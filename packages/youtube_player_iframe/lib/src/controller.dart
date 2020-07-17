// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'enums/player_state.dart';
import 'enums/playlist_type.dart';
import 'enums/thumbnail_quality.dart';
import 'enums/youtube_error.dart';
import 'meta_data.dart';
import 'player_params.dart';
import 'player_value.dart';

/// Controls a youtube player, and provides updates when the state is changing.
///
/// The video is displayed in a Flutter app by creating a [YoutubePlayerIFrame] widget.
///
/// After [YoutubePlayerController.close] all further calls are ignored.
class YoutubePlayerController extends Stream<YoutubePlayerValue>
    implements Sink<YoutubePlayerValue> {
  /// Creates [YoutubePlayerController].
  YoutubePlayerController({
    @required this.initialVideoId,
    this.params = const YoutubePlayerParams(),
  }) {
    invokeJavascript = (_) {};
  }

  /// The Youtube video id for initial video to be loaded.
  final String initialVideoId;

  /// Defines default parameters for the player.
  final YoutubePlayerParams params;

  /// Can be used to invokes javascript function.
  ///
  /// Ensure that the player is ready before using this.
  void Function(String function) invokeJavascript;

  /// Called when player enters fullscreen.
  VoidCallback onEnterFullscreen;

  /// Called when player exits fullscreen.
  VoidCallback onExitFullscreen;

  final StreamController<YoutubePlayerValue> _controller =
      StreamController.broadcast();

  YoutubePlayerValue _value = YoutubePlayerValue();

  /// The [YoutubePlayerValue].
  YoutubePlayerValue get value => _value;

  /// Updates [YoutubePlayerController] with provided [data].
  ///
  /// Intended for internal usage only.
  @override
  void add(YoutubePlayerValue data) => _controller.add(data);

  /// Listen to updates in [YoutubePlayerController].
  @override
  StreamSubscription<YoutubePlayerValue> listen(
    void Function(YoutubePlayerValue event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    return _controller.stream.listen(
      (value) {
        _value = value;
        onData(value);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Closes [YoutubePlayerController].
  ///
  /// Call when the controller is no longer used.
  @override
  Future<void> close() => _controller.close();

  /// Plays the currently cued/loaded video.
  ///
  /// The final player state after this function executes will be [PlayerState.playing].
  ///
  /// Note: A playback only counts toward a video's official view count if it is initiated via a native play button in the player.
  void play() => invokeJavascript('play()');

  /// Pauses the currently playing video.
  ///
  /// The final player state after this function executes will be [PlayerState.paused] unless the player is in the [PlayerState.ended] state when the function is called,
  /// in which case the player state will not change.
  void pause() => invokeJavascript('pause()');

  /// Stops and cancels loading of the current video.
  ///
  /// This function should be reserved for rare situations when you know that the user will not be watching additional video in the player.
  /// If your intent is to pause the video, you should just call the [YoutubePlayerController.pause] function.
  /// If you want to change the video that the player is playing, you can call one of the queueing functions without calling [YoutubePlayerController.stop] first.
  void stop() => invokeJavascript('stop()');

  /// This function loads and plays the next video in the playlist.
  ///
  /// If called while the last video in the playlist is being watched, and the playlist is set to play continuously (i.e. [YoutubePlayerParams.loop] is true),
  /// then the player will load and play the first video in the list, otherwise,
  /// the playback will end.
  void nextVideo() => invokeJavascript('next()');

  /// This function loads and plays the previous video in the playlist.
  ///
  /// If called while the last video in the playlist is being watched, and the playlist is set to play continuously (i.e. [YoutubePlayerParams.loop] is true),
  /// then the player will load and play the first video in the list, otherwise,
  /// the playback will end.
  void previousVideo() => invokeJavascript('previous()');

  /// This function loads and plays the specified video in the playlist.
  ///
  /// The [index] parameter specifies the index of the video that you want to play in the playlist.
  /// The parameter uses a zero-based index, so a value of 0 identifies the first video in the list.
  /// If you have shuffled the playlist, this function will play the video at the specified position in the shuffled playlist.
  void playVideoAt(int index) => invokeJavascript('playVideoAt($index)');

  /// This function loads and plays the specified video.
  ///
  /// [videoId] specifies the YouTube Video ID of the video to be played.
  /// In the YouTube Data API, a video resource's id property specifies the ID.
  ///
  /// [startAt] & [endAt] parameter accepts a [Duration].
  /// If specified, then the video will (start from the closest keyframe to the specified time / end at the specified time).
  void load(String videoId,
      {Duration startAt = Duration.zero, Duration endAt}) {
    var loadParams = 'videoId:"$videoId",startSeconds:${startAt.inSeconds}';
    if (endAt != null && endAt > startAt) {
      loadParams += ',endSeconds:${endAt.inSeconds}';
    }
    _updateId(videoId);
    if (_value.hasError) {
      pause();
    } else {
      invokeJavascript('loadById({$loadParams})');
    }
  }

  /// This function loads the specified video's thumbnail and prepares the player to play the video.
  /// The player does not request the FLV until [YoutubePlayerController.play] or [YoutubePlayerController.seekTo] is called.
  ///
  /// [videoId] parameter specifies the YouTube Video ID of the video to be played.
  /// In the YouTube Data API, a video resource's id property specifies the ID.
  ///
  /// [startAt] & [endAt] parameter accepts a [Duration].
  /// If specified, then the video will (start from the closest keyframe to the specified time / end at the specified time).
  void cue(String videoId, {Duration startAt = Duration.zero, Duration endAt}) {
    var cueParams = 'videoId:"$videoId",startSeconds:${startAt.inSeconds}';
    if (endAt != null && endAt > startAt) {
      cueParams += ',endSeconds:${endAt.inSeconds}';
    }
    _updateId(videoId);
    if (_value.hasError) {
      pause();
    } else {
      invokeJavascript('cueById({$cueParams})');
    }
  }

  /// This function loads the specified list and plays it.
  /// The list can be a playlist, a search results feed, or a user's uploaded videos feed.
  ///
  /// [list] contains a key that identifies the particular list of videos that YouTube should return.
  /// [listType] specifies the type of results feed that you are retrieving.
  /// [startAt] accepts a [Duration] and specifies the time from which the first video in the list should start playing.
  /// [index] specifies the index of the first video in the list that will play.
  /// The parameter uses a zero-based index, and the default parameter value is 0,
  /// so the default behavior is to load and play the first video in the list.
  void loadPlaylist(
    String list, {
    String listType = PlaylistType.playlist,
    int startAt = 0,
    int index = 0,
  }) {
    var loadParams =
        'list:"$list",listType:"$listType",index:$index,startSeconds:$startAt';
    invokeJavascript('loadPlaylist({$loadParams})');
  }

  /// Queues the specified list of videos.
  /// The list can be a playlist, a search results feed, or a user's uploaded videos feed.
  /// When the list is cued and ready to play, the player will broadcast a video cued event [PlayerState.cued].
  ///
  /// [list] contains a key that identifies the particular list of videos that YouTube should return.
  /// [listType] specifies the type of results feed that you are retrieving.
  /// [startAt] accepts a [Duration] and specifies the time from which the first video in the list should start playing.
  /// [index] specifies the index of the first video in the list that will play.
  /// The parameter uses a zero-based index, and the default parameter value is 0,
  /// so the default behavior is to load and play the first video in the list.
  void cuePlaylist(
    String list, {
    String listType = PlaylistType.playlist,
    int startAt = 0,
    int index = 0,
  }) {
    var cueParams =
        'list:"$list",listType:"$listType",index:$index,startSeconds:$startAt';
    invokeJavascript('cuePlaylist({$cueParams})');
  }

  void _updateId(String id) {
    if (id?.length != 11) {
      add(_value.copyWith(error: YoutubeError.invalidParam));
    } else {
      add(_value.copyWith(error: YoutubeError.none, hasPlayed: false));
    }
  }

  /// Mutes the player.
  void mute() => invokeJavascript('mute()');

  /// Unmutes the player.
  void unMute() => invokeJavascript('unMute()');

  /// Sets the volume of player.
  /// Max = 100 , Min = 0
  void setVolume(int volume) => volume >= 0 && volume <= 100
      ? invokeJavascript('setVolume($volume)')
      : throw Exception("Volume should be between 0 and 100");

  /// Seeks to a specified time in the video.
  ///
  /// If the player is paused when the function is called, it will remain paused.
  /// If the function is called from another state (playing, video cued, etc.), the player will play the video.
  ///
  /// [allowSeekAhead] determines whether the player will make a new request to the server
  /// if the seconds parameter specifies a time outside of the currently buffered video data.
  ///
  /// Default allowSeekAhead = true
  void seekTo(Duration position, {bool allowSeekAhead = true}) {
    invokeJavascript('seekTo(${position.inSeconds},$allowSeekAhead)');
    play();
    add(_value.copyWith(position: position));
  }

  /// Sets the size in pixels of the player.
  void setSize(Size size) =>
      invokeJavascript('setSize(${size.width}, ${size.height})');

  /// Sets the playback speed for the video.
  void setPlaybackRate(double rate) =>
      invokeJavascript('setPlaybackRate($rate)');

  /// This function indicates whether the video player should continuously play a playlist
  /// or if it should stop playing after the last video in the playlist ends.
  ///
  /// The default behavior is that playlists do not loop.
  // ignore: avoid_positional_boolean_parameters
  void setLoop(bool loop) => invokeJavascript('setLoop($loop)');

  /// This function indicates whether a playlist's videos should be shuffled so that they play back in an order different from the one that the playlist creator designated.
  ///
  /// If you shuffle a playlist after it has already started playing, the list will be reordered while the video that is playing continues to play.
  /// The next video that plays will then be selected based on the reordered list.
  // ignore: avoid_positional_boolean_parameters
  void setShuffle(bool shuffle) => invokeJavascript('setShuffle($shuffle)');

  /// Hides top menu i.e. title, playlist, share icon shown at top of the player.
  ///
  /// Might violates Youtube's TOS. Use at your own risk.
  void hideTopMenu() => invokeJavascript('hideTopMenu()');

  /// Hides pause overlay i.e. related videos shown when player is paused.
  ///
  /// Might violates Youtube's TOS. Use at your own risk.
  void hidePauseOverlay() => invokeJavascript('hidePauseOverlay()');

  /// MetaData for the currently loaded or cued video.
  YoutubeMetaData get metadata => _value.metaData;

  /// Resets the value of [YoutubePlayerController].
  void reset() => add(
        _value.copyWith(
          isReady: false,
          isFullScreen: false,
          playerState: PlayerState.unknown,
          hasPlayed: false,
          position: Duration.zero,
          buffered: 0.0,
          error: YoutubeError.none,
          metaData: const YoutubeMetaData(),
        ),
      );

  /// Converts fully qualified YouTube Url to video id.
  ///
  /// If videoId is passed as url then no conversion is done.
  static String convertUrlToId(String url, {bool trimWhitespaces = true}) {
    assert(url?.isNotEmpty ?? false, 'Url cannot be empty');
    if (!url.contains("http") && (url.length == 11)) return url;
    if (trimWhitespaces) url = url.trim();

    for (var regex in [
      r'^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$',
      r'^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$',
      r'^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$',
    ]) {
      Match match = RegExp(regex).firstMatch(url);
      if (match != null && match.groupCount >= 1) return match.group(1);
    }

    return null;
  }

  /// Grabs YouTube video's thumbnail for provided video id.
  ///
  /// If [webp] is true, webp version of the thumbnail will be retrieved,
  /// Otherwise a JPG thumbnail.
  static String getThumbnail({
    @required String videoId,
    String quality = ThumbnailQuality.standard,
    bool webp = true,
  }) {
    return webp
        ? 'https://i3.ytimg.com/vi_webp/$videoId/$quality.webp'
        : 'https://i3.ytimg.com/vi/$videoId/$quality.jpg';
  }
}
