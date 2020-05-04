// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_media/platform_interface.dart';
import 'package:webview_media/webview_flutter.dart';

import '../enums/player_state.dart';
import '../utils/youtube_meta_data.dart';
import '../utils/youtube_player_controller.dart';

/// A raw youtube player widget which interacts with the underlying webview inorder to play YouTube videos.
///
/// Use [YoutubePlayer] instead.
class RawYoutubePlayer extends StatefulWidget {
  /// Sets [Key] as an identification to underlying web view associated to the player.
  final Key key;

  /// {@macro youtube_player_flutter.onEnded}
  final void Function(YoutubeMetaData metaData) onEnded;

  /// Creates a [RawYoutubePlayer] widget.
  RawYoutubePlayer({
    this.key,
    this.onEnded,
  });

  @override
  _RawYoutubePlayerState createState() => _RawYoutubePlayerState();
}

class _RawYoutubePlayerState extends State<RawYoutubePlayer>
    with WidgetsBindingObserver {
  final Completer<WebViewController> _webController =
      Completer<WebViewController>();
  YoutubePlayerController controller;
  PlayerState _cachedPlayerState;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_cachedPlayerState != null &&
            _cachedPlayerState == PlayerState.playing) {
          controller?.play();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _cachedPlayerState = controller.value.playerState;
        controller?.pause();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    controller = YoutubePlayerController.of(context);
    return IgnorePointer(
      ignoring: true,
      child: WebView(
        key: widget.key,
        userAgent: userAgent,
        initialData: WebData(
          data: player,
          baseUrl: 'https://www.youtube.com',
          encoding: 'utf-8',
          mimeType: 'text/html',
        ),
        onWebResourceError: (WebResourceError error) {
          controller
              .updateValue(controller.value.copyWith(webResourceError: error));
        },
        javascriptMode: JavascriptMode.unrestricted,
        initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
        javascriptChannels: {
          JavascriptChannel(
            name: 'Ready',
            onMessageReceived: (JavascriptMessage message) {
              _isPlayerReady = true;
            },
          ),
          JavascriptChannel(
            name: 'StateChange',
            onMessageReceived: (JavascriptMessage message) {
              switch (message.message) {
                case '-1':
                  controller.updateValue(
                    controller.value.copyWith(
                      playerState: PlayerState.unStarted,
                      isLoaded: true,
                    ),
                  );
                  break;
                case '0':
                  if (widget.onEnded != null) {
                    widget.onEnded(controller.metadata);
                  }
                  controller.updateValue(
                    controller.value.copyWith(
                      playerState: PlayerState.ended,
                    ),
                  );
                  break;
                case '1':
                  controller.updateValue(
                    controller.value.copyWith(
                      playerState: PlayerState.playing,
                      isPlaying: true,
                      hasPlayed: true,
                      errorCode: 0,
                    ),
                  );
                  break;
                case '2':
                  controller.updateValue(
                    controller.value.copyWith(
                      playerState: PlayerState.paused,
                      isPlaying: false,
                    ),
                  );
                  break;
                case '3':
                  controller.updateValue(
                    controller.value.copyWith(
                      playerState: PlayerState.buffering,
                    ),
                  );
                  break;
                case '5':
                  controller.updateValue(
                    controller.value.copyWith(
                      playerState: PlayerState.cued,
                    ),
                  );
                  break;
                default:
                  throw Exception("Invalid player state obtained.");
              }
            },
          ),
          JavascriptChannel(
            name: 'PlaybackQualityChange',
            onMessageReceived: (JavascriptMessage message) {
              controller.updateValue(
                controller.value.copyWith(
                  playbackQuality: message.message,
                ),
              );
            },
          ),
          JavascriptChannel(
            name: 'PlaybackRateChange',
            onMessageReceived: (JavascriptMessage message) {
              controller.updateValue(
                controller.value.copyWith(
                  playbackRate: double.tryParse(message.message) ?? 1.0,
                ),
              );
            },
          ),
          JavascriptChannel(
            name: 'Errors',
            onMessageReceived: (JavascriptMessage message) {
              controller.updateValue(
                controller.value
                    .copyWith(errorCode: int.tryParse(message.message) ?? 0),
              );
            },
          ),
          JavascriptChannel(
            name: 'VideoData',
            onMessageReceived: (JavascriptMessage message) {
              controller.updateValue(
                controller.value.copyWith(
                  metaData: YoutubeMetaData.fromRawData(message.message),
                ),
              );
            },
          ),
          JavascriptChannel(
            name: 'CurrentTime',
            onMessageReceived: (JavascriptMessage message) {
              var position = (double.tryParse(message.message) ?? 0) * 1000;
              controller.updateValue(
                controller.value.copyWith(
                  position: Duration(milliseconds: position.floor()),
                ),
              );
            },
          ),
          JavascriptChannel(
            name: 'LoadedFraction',
            onMessageReceived: (JavascriptMessage message) {
              controller.updateValue(
                controller.value.copyWith(
                  buffered: double.tryParse(message.message) ?? 0,
                ),
              );
            },
          ),
        },
        onWebViewCreated: (webController) {
          _webController.complete(webController);
          _webController.future.then(
            (webViewController) {
              controller.updateValue(
                controller.value.copyWith(webViewController: webViewController),
              );
            },
          );
        },
        onPageFinished: (_) {
          if (_isPlayerReady) {
            controller.updateValue(
              controller.value.copyWith(isReady: true),
            );
          } else {
            controller.reload();
          }
        },
      ),
    );
  }

  String get player => '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            html,
            body {
                margin: 0;
                padding: 0;
                background-color: #000000;
                overflow: hidden;
                position: fixed;
                height: 100%;
                width: 100%;
            }
        </style>
        <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
    </head>
    <body>
        <div id="player"></div>
        <script>
            var tag = document.createElement('script');
            tag.src = "https://www.youtube.com/iframe_api";
            var firstScriptTag = document.getElementsByTagName('script')[0];
            firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
            var player;
            var timerId;
            function onYouTubeIframeAPIReady() {
                player = new YT.Player('player', {
                    height: '100%',
                    width: '100%',
                    videoId: '${controller.initialVideoId}',
                    host: 'https://www.youtube.com',
                    playerVars: {
                        'controls': 0,
                        'playsinline': 1,
                        'enablejsapi': 1,
                        'fs': 0,
                        'rel': 0,
                        'showinfo': 0,
                        'iv_load_policy': 3,
                        'modestbranding': 1,
                        'cc_load_policy': ${boolean(value: controller.flags.enableCaption)},
                        'cc_lang_pref': '${controller.flags.captionLanguage}',
                        'autoplay': ${boolean(value: controller.flags.autoPlay)}
                    },
                    events: {
                        onReady: function(event) { Ready.postMessage("Ready"); },
                        onStateChange: function(event) { sendPlayerStateChange(event.data); },
                        onPlaybackQualityChange: function(event) { PlaybackQualityChange.postMessage(event.data); },
                        onPlaybackRateChange: function(event) { PlaybackRateChange.postMessage(event.data); },
                        onError: function(error) { Errors.postMessage(error.data); }
                    },
                });
            }

            function sendPlayerStateChange(playerState) {
                clearTimeout(timerId);
                StateChange.postMessage(playerState);
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
                VideoData.postMessage(JSON.stringify(videoData));
            }

            function startSendCurrentTimeInterval() {
                timerId = setInterval(function () {
                    CurrentTime.postMessage(player.getCurrentTime());
                    LoadedFraction.postMessage(player.getVideoLoadedFraction());
                }, 100);
            }

            function play() {
                player.playVideo();
                return '';
            }

            function pause() {
                player.pauseVideo();
                return '';
            }

            function loadById(id, startAt, endAt) {
                player.loadVideoById(id, startAt, endAt);
                return '';
            }

            function cueById(id, startAt, endAt) {
                player.cueVideoById(id, startAt, endAt);
                return '';
            }
            
            function loadPlaylist(playlist, index, startAt) {
                player.loadPlaylist(playlist, 'playlist', index, startAt);
                return '';
            }
            
            function cuePlaylist(playlist, index, startAt) {
                player.cuePlaylist(playlist, 'playlist', index, startAt);
                return '';
            }

            function mute() {
                player.mute();
                return '';
            }

            function unMute() {
                player.unMute();
                return '';
            }

            function setVolume(volume) {
                player.setVolume(volume);
                return '';
            }

            function seekTo(position, seekAhead) {
                player.seekTo(position, seekAhead);
                return '';
            }

            function setSize(width, height) {
                player.setSize(width, height);
                return '';
            }

            function setPlaybackRate(rate) {
                player.setPlaybackRate(rate);
                return '';
            }
            
            function setTopMargin(margin) {
                document.getElementById("player").style.marginTop = margin;
                return '';
            }
        </script>
    </body>
    </html>
  ''';

  String boolean({@required bool value}) => value ? "'1'" : "'0'";

  String get userAgent => controller.flags.forceHD
      ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36'
      : null;
}
