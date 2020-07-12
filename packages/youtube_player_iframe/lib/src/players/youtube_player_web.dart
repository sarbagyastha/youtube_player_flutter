// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';
import 'dart:html';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/src/enums/player_state.dart';
import 'package:youtube_player_iframe/src/enums/youtube_error.dart';
import 'package:youtube_player_iframe/src/helpers/player_fragments.dart';

import '../controller.dart';
import '../meta_data.dart';

/// A youtube player widget which interacts with the underlying iframe inorder to play YouTube videos.
///
/// Use [YoutubePlayerIFrame] instead.
class RawYoutubePlayer extends StatefulWidget {
  /// Sets [Key] as an identification to underlying web view associated to the player.
  final Key key;

  /// The [YoutubePlayerController].
  final YoutubePlayerController controller;

  /// Creates a [MobileYoutubePlayer] widget.
  const RawYoutubePlayer(
    this.controller, {
    this.key,
  });

  @override
  _WebYoutubePlayerState createState() => _WebYoutubePlayerState();
}

class _WebYoutubePlayerState extends State<RawYoutubePlayer> {
  static final _iFrameMap = <int, IFrameElement>{};
  YoutubePlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    if (_iFrameMap[controller.hashCode] == null) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'youtube-player-${controller.hashCode}',
        (int id) {
          _iFrameMap[controller.hashCode] = IFrameElement()
            ..srcdoc = player
            ..style.border = 'none';
          window.onMessage.listen(
            (event) {
              final Map<String, dynamic> data = jsonDecode(event.data);
              if (data.containsKey('Ready')) {
                controller.add(
                  controller.value.copyWith(isReady: true),
                );
              }

              if (data.containsKey('StateChange')) {
                switch (data['StateChange'] as int) {
                  case -1:
                    controller.add(
                      controller.value.copyWith(
                        playerState: PlayerState.unStarted,
                        isReady: true,
                      ),
                    );
                    break;
                  case 0:
                    controller.add(
                      controller.value.copyWith(
                        playerState: PlayerState.ended,
                      ),
                    );
                    break;
                  case 1:
                    controller.add(
                      controller.value.copyWith(
                        playerState: PlayerState.playing,
                        hasPlayed: true,
                        error: YoutubeError.none,
                      ),
                    );
                    break;
                  case 2:
                    controller.add(
                      controller.value.copyWith(
                        playerState: PlayerState.paused,
                      ),
                    );
                    break;
                  case 3:
                    controller.add(
                      controller.value.copyWith(
                        playerState: PlayerState.buffering,
                      ),
                    );
                    break;
                  case 5:
                    controller.add(
                      controller.value.copyWith(
                        playerState: PlayerState.cued,
                      ),
                    );
                    break;
                  default:
                    throw Exception("Invalid player state obtained.");
                }
              }

              if (data.containsKey('PlaybackQualityChange')) {
                controller.add(
                  controller.value.copyWith(
                      playbackQuality: data['PlaybackQualityChange'] as String),
                );
              }

              if (data.containsKey('PlaybackRateChange')) {
                final rate = data['PlaybackRateChange'] as num;
                controller.add(
                  controller.value.copyWith(playbackRate: rate.toDouble()),
                );
              }

              if (data.containsKey('Errors')) {
                controller.add(
                  controller.value
                      .copyWith(error: errorEnum(data['Errors'] as int)),
                );
              }

              if (data.containsKey('VideoData')) {
                controller.add(
                  controller.value.copyWith(
                      metaData: YoutubeMetaData.fromRawData(data['VideoData'])),
                );
              }

              if (data.containsKey('VideoTime')) {
                final position = data['VideoTime']['currentTime'] as double;
                final buffered =
                    data['VideoTime']['videoLoadedFraction'] as num;

                if (position == null || buffered == null) return;
                controller.add(
                  controller.value.copyWith(
                    position: Duration(milliseconds: (position * 1000).floor()),
                    buffered: buffered.toDouble(),
                  ),
                );
              }
            },
          );
          controller.invokeJavascript = _callMethod;
          return _iFrameMap[controller.hashCode];
        },
      );
    }
  }

  void _callMethod(String methodName) {
    if (_iFrameMap[controller.hashCode] == null) {
      log('Youtube Player is not ready for method calls.');
      return;
    }
    _iFrameMap[controller.hashCode].contentWindow.postMessage(methodName, '*');
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: ValueKey(controller.hashCode),
      viewType: 'youtube-player-${controller.hashCode}',
    );
  }

  String get player => '''
    <!DOCTYPE html>
    <html>
    $playerDocHead
    <body>
        <div id="player"></div>
        <script>
            $initPlayerIFrame
            var player;
            var timerId;
            function onYouTubeIframeAPIReady() {
                player = new YT.Player('player', {
                    height: '100%',
                    width: '100%',
                    videoId: '${controller.initialVideoId}',
                    playerVars: ${playerVars(controller)},
                    events: {
                      onReady: (event) => sendMessage({ 'Ready': true }),
                      onStateChange: (event) => sendPlayerStateChange(event.data),
                      onPlaybackQualityChange: (event) => sendMessage({ 'PlaybackQualityChange': event.data }),
                      onPlaybackRateChange: (event) => sendMessage({ 'PlaybackRateChange': event.data }),
                      onError: (error) => sendMessage({ 'Errors': event.data }),
                    },
                });
            }
            
            window.addEventListener('message', (event) => {
               try { eval(event.data) } catch (e) {}
            }, false);
            
            function sendMessage(message) {
              window.parent.postMessage(JSON.stringify(message), '*');
            }

            function sendPlayerStateChange(playerState) {
                clearTimeout(timerId);
                sendMessage({ 'StateChange': playerState });
                if (playerState == 1) {
                    startSendCurrentTimeInterval();
                    sendVideoData(player);
                }
            }

            function sendVideoData(player) {
                var videoData = {
                    'duration': player.getDuration(),
                    'title': player.getVideoData().title,
                    'author': player.getVideoData().author,
                    'videoId': player.getVideoData().video_id
                };
                sendMessage({ 'VideoData': videoData });
            }

            function startSendCurrentTimeInterval() {
                timerId = setInterval(function () {
                  var videoTime = {
                      'currentTime': player.getCurrentTime(),
                      'videoLoadedFraction': player.getVideoLoadedFraction()
                  };
                  sendMessage({ 'VideoTime': videoTime });
                }, 100);
            }
            
            $youtubeIFrameFunctions
        </script>
    </body>
    </html>
  ''';
}
