// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/src/enums/youtube_error.dart';
import 'package:youtube_player_iframe/src/helpers/player_fragments.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../controller.dart';
import '../enums/player_state.dart';
import '../meta_data.dart';

/// A youtube player widget which interacts with the underlying webview inorder to play YouTube videos.
///
/// Use [YoutubePlayerIFrame] instead.
class RawYoutubePlayer extends StatefulWidget {
  /// Sets [Key] as an identification to underlying web view associated to the player.
  final Key key;

  /// The [YoutubePlayerController].
  final YoutubePlayerController controller;

  /// Creates a [RawYoutubePlayer] widget.
  const RawYoutubePlayer(
    this.controller, {
    this.key,
  });

  @override
  _MobileYoutubePlayerState createState() => _MobileYoutubePlayerState();
}

class _MobileYoutubePlayerState extends State<RawYoutubePlayer>
    with WidgetsBindingObserver {
  YoutubePlayerController controller;
  Completer<WebViewController> _webController;
  PlayerState _cachedPlayerState;
  bool _isPlayerReady = false;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    _webController = Completer();
    controller = widget.controller;
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
    return WebView(
      key: ValueKey(controller.hashCode),
      initialUrl: _playerData,
      javascriptMode: JavascriptMode.unrestricted,
      initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
      javascriptChannels: _javascriptChannels,
      navigationDelegate: (navRequest) {
        final uri = Uri.parse(navRequest.url);
        final feature = uri.queryParameters['feature'];
        if (feature == 'emb_rel_pause') {
          controller.load(uri.queryParameters['v']);
        } else {
          url_launcher.launch(navRequest.url);
        }
        return NavigationDecision.prevent;
      },
      userAgent: userAgent,
      gestureRecognizers: {
        Factory<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(),
        ),
        Factory<HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
        ),
      },
      onWebViewCreated: (webController) {
        _webController.complete(webController);
        controller.invokeJavascript = _callMethod;
      },
      onPageFinished: (_) {
        _pageLoaded = true;
        controller.add(controller.value.copyWith(isReady: _isPlayerReady));
      },
      onWebResourceError: (error) {
        final tag = 'Youtube Player Resource Error';
        log('*' * 80, name: tag);
        log('Domain: ${error.domain}', name: tag);
        log('Description: ${error.description}', name: tag);
        log('Error Code: ${error.errorCode}', name: tag);
        log('Error Type: ${error.errorType}', name: tag);
        log('Failing URL: ${error.failingUrl}', name: tag);
        log('*' * 80, name: tag);
      },
    );
  }

  Set<JavascriptChannel> get _javascriptChannels => {
        JavascriptChannel(
          name: 'Ready',
          onMessageReceived: (_) {
            _isPlayerReady = true;
            controller.add(controller.value.copyWith(isReady: _pageLoaded));
          },
        ),
        JavascriptChannel(
          name: 'StateChange',
          onMessageReceived: (state) => _onPlaybackStateChanged(state.message),
        ),
        JavascriptChannel(
          name: 'VideoData',
          onMessageReceived: (videoData) {
            controller.add(
              controller.value.copyWith(
                metaData: YoutubeMetaData.fromRawData(videoData.message),
              ),
            );
          },
        ),
        JavascriptChannel(
          name: 'VideoTime',
          onMessageReceived: (videoTime) {
            final rawVideoTime = jsonDecode(videoTime.message);
            final position = rawVideoTime['currentTime'] * 1000;
            final num buffered = rawVideoTime['loadedFraction'];
            controller.add(
              controller.value.copyWith(
                position: Duration(milliseconds: position.floor()),
                buffered: buffered.toDouble(),
              ),
            );
          },
        ),
        JavascriptChannel(
          name: 'PlaybackQualityChange',
          onMessageReceived: (quality) {
            controller.add(
              controller.value.copyWith(playbackQuality: quality.message),
            );
          },
        ),
        JavascriptChannel(
          name: 'PlaybackRateChange',
          onMessageReceived: (rate) {
            controller.add(
              controller.value.copyWith(
                playbackRate: double.parse(rate.message),
              ),
            );
          },
        ),
        JavascriptChannel(
          name: 'Errors',
          onMessageReceived: (error) {
            controller.add(
              controller.value.copyWith(error: errorEnum(error.message)),
            );
          },
        ),
      };

  void _onPlaybackStateChanged(String playbackCode) {
    switch (playbackCode) {
      case '-1':
        controller.add(
          controller.value
              .copyWith(playerState: PlayerState.unStarted, isReady: true),
        );
        break;
      case '0':
        controller.add(
          controller.value.copyWith(playerState: PlayerState.ended),
        );
        break;
      case '1':
        controller.add(
          controller.value.copyWith(
            playerState: PlayerState.playing,
            hasPlayed: true,
            error: YoutubeError.none,
          ),
        );
        break;
      case '2':
        controller.add(
          controller.value.copyWith(playerState: PlayerState.paused),
        );
        break;
      case '3':
        controller.add(
          controller.value.copyWith(playerState: PlayerState.buffering),
        );
        break;
      case '5':
        controller.add(
          controller.value.copyWith(playerState: PlayerState.cued),
        );
        break;
      default:
        throw Exception("Invalid player state obtained.");
    }
  }

  Future<void> _callMethod(String methodName) async {
    final webController = await _webController.future;
    webController.evaluateJavascript(methodName);
  }

  String get _playerData {
    final playerBase64 = base64Encode(const Utf8Encoder().convert(_player));
    return 'data:text/html;base64,$playerBase64';
  }

  String get _player => '''
    <!DOCTYPE html>
    <body>
        ${youtubeIFrameTag(controller)}
        <script>
            $initPlayerIFrame
            var player;
            var timerId;
            function onYouTubeIframeAPIReady() {
                player = new YT.Player('player', {
                    events: {
                        onReady: function(event) { Ready.postMessage('Ready'); },
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
                var videoTimeData = {
                    'currentTime': player.getCurrentTime(),
                    'loadedFraction': player.getVideoLoadedFraction()
                };
                VideoTime.postMessage(JSON.stringify(videoTimeData));
                }, 100);
            }

            $youtubeIFrameFunctions
        </script>
    </body>
  ''';

  String boolean({@required bool value}) => value ? "'1'" : "'0'";

  String get userAgent => controller.params.desktopMode
      ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36'
      : null;
}
