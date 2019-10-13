part of 'youtube_player.dart';

class _Player extends StatefulWidget {
  final YoutubePlayerController controller;
  final YoutubePlayerFlags flags;

  _Player({
    this.controller,
    this.flags,
  });

  @override
  __PlayerState createState() => __PlayerState();
}

class __PlayerState extends State<_Player> with WidgetsBindingObserver {
  Completer<WebViewController> _webController = Completer<WebViewController>();

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
        if(widget.flags.autoPlay){
          widget.controller?.play();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.suspending:
        widget.controller?.pause();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: WebView(
        initialUrl: player,
        javascriptMode: JavascriptMode.unrestricted,
        initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
        javascriptChannels: {
          JavascriptChannel(
            name: 'Ready',
            onMessageReceived: (JavascriptMessage message) {
              widget.controller.value =
                  widget.controller.value.copyWith(isReady: true);
            },
          ),
          JavascriptChannel(
            name: 'StateChange',
            onMessageReceived: (JavascriptMessage message) {
              switch (message.message) {
                case '-1':
                  widget.controller.value = widget.controller.value.copyWith(
                      playerState: PlayerState.unStarted, isLoaded: true);
                  break;
                case '0':
                  widget.controller.value = widget.controller.value
                      .copyWith(playerState: PlayerState.ended);
                  break;
                case '1':
                  widget.controller.value = widget.controller.value.copyWith(
                    playerState: PlayerState.playing,
                    isPlaying: true,
                    hasPlayed: true,
                    errorCode: 0,
                  );
                  break;
                case '2':
                  widget.controller.value = widget.controller.value.copyWith(
                    playerState: PlayerState.paused,
                    isPlaying: false,
                  );
                  break;
                case '3':
                  widget.controller.value = widget.controller.value
                      .copyWith(playerState: PlayerState.buffering);
                  break;
                case '5':
                  widget.controller.value = widget.controller.value
                      .copyWith(playerState: PlayerState.cued);
                  break;
                default:
                  throw Exception("Invalid player state obtained.");
              }
            },
          ),
          JavascriptChannel(
            name: 'PlaybackQualityChange',
            onMessageReceived: (JavascriptMessage message) {
              print("PlaybackQualityChange ${message.message}");
            },
          ),
          JavascriptChannel(
            name: 'PlaybackRateChange',
            onMessageReceived: (JavascriptMessage message) {
              widget.controller.value = widget.controller.value.copyWith(
                playbackRate: playbackRateMap.map<double, PlaybackRate>((k,
                        v) =>
                    MapEntry(v, k))[double.tryParse(message.message) ?? 1.0],
              );
            },
          ),
          JavascriptChannel(
            name: 'Errors',
            onMessageReceived: (JavascriptMessage message) {
              widget.controller.value = widget.controller.value
                  .copyWith(errorCode: int.tryParse(message.message) ?? 0);
            },
          ),
          JavascriptChannel(
            name: 'VideoData',
            onMessageReceived: (JavascriptMessage message) {
              var videoData = jsonDecode(message.message);
              double duration = videoData['duration'] * 1000;
              print("VideoData ${message.message}");
              widget.controller.value = widget.controller.value.copyWith(
                duration: Duration(
                  milliseconds: duration.floor(),
                ),
              );
            },
          ),
          JavascriptChannel(
            name: 'CurrentTime',
            onMessageReceived: (JavascriptMessage message) {
              double position = (double.tryParse(message.message) ?? 0) * 1000;
              widget.controller.value = widget.controller.value.copyWith(
                position: Duration(
                  milliseconds: position.floor(),
                ),
              );
            },
          ),
          JavascriptChannel(
            name: 'LoadedFraction',
            onMessageReceived: (JavascriptMessage message) {
              widget.controller.value = widget.controller.value.copyWith(
                buffered: double.tryParse(message.message) ?? 0,
              );
            },
          ),
        },
        onWebViewCreated: (webController) {
          _webController.complete(webController);
          _webController.future.then(
            (controller) {
              widget.controller.value = widget.controller.value
                  .copyWith(webViewController: webController);
            },
          );
        },
        onPageFinished: (_) {
          widget.controller.value = widget.controller.value.copyWith(
            isEvaluationReady: true,
          );
        },
      ),
    );
  }

  String get player {
    String _player = '''
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
    ''';
    if (widget.flags.forceHideAnnotation) {
      _player += '''
      height: 1000%;
      width: 1000%;
      transform: scale(0.1);
      transform-origin: left top;
      ''';
    } else {
      _player += '''
      height: 100%;
      width: 100%;
      ''';
    }
    _player += '''
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
                    videoId: '50kklGefAcs',
                    playerVars: {
                        'controls': 0,
                        'playsinline': 1,
                        'enablejsapi': 1,
                        'fs': 0,
                        'rel': 0,
                        'showinfo': 0,
                        'iv_load_policy': 3,
                        'modestbranding': 1,
    ''';
    if (widget.flags.start != null)
      _player += "'start': ${widget.flags.start.inSeconds},";
    if (widget.flags.end != null)
      _player += "'end': ${widget.flags.end.inSeconds},";
    _player += '''
                        'cc_load_policy': ${boolean(widget.flags.enableCaption)},
                        'cc_lang_pref': '${widget.flags.captionLanguage}',
                        'autoplay': ${boolean(widget.flags.autoPlay)},
                        'loop': ${boolean(widget.flags.loop)},
                    },
                    events: {
                        onReady: (event) => Ready.postMessage("Ready"),
                        onStateChange: (event) => sendPlayerStateChange(event.data),
                        onPlaybackQualityChange: (event) => PlaybackQualityChange.postMessage(event.data),
                        onPlaybackRateChange: (event) => PlaybackRateChange.postMessage(event.data),
                        onError: (error) => Errors.postMessage(error.data)
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
                    'videoUrl': player.getVideoUrl(),
                    'availableQualityLevels': player.getAvailableQualityLevels(),
                    'videoEmbedCode': player.getVideoEmbedCode(),
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

            function loadById(id, startAt) {
                player.loadVideoById(id, startAt);
                return '';
            }

            function cueById(id, startAt) {
                player.cueVideoById(id, startAt);
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
        </script>
    </body>
    </html>
    ''';
    return 'data:text/html;base64,${base64Encode(const Utf8Encoder().convert(_player))}';
  }

  String boolean(bool value) => value ? "'1'" : "'0'";
}