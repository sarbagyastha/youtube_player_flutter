![YOUTUBE PLAYER FLUTTER](misc/ypf_banner.png)

[![pub package](https://img.shields.io/pub/v/youtube_player_flutter.svg)](https://pub.dartlang.org/packages/youtube_player_flutter)
[![Build Status](https://travis-ci.org/sarbagyastha/youtube_player_flutter.svg?branch=master)](https://travis-ci.org/sarbagyastha/youtube_player_flutter)
[![licence](https://img.shields.io/badge/licence-BSD-orange.svg)](https://github.com/sarbagyastha/youtube_player_flutter/blob/master/LICENSE)
[![Download](https://img.shields.io/badge/download-APK-informational.svg)](https://github.com/sarbagyastha/youtube_player_flutter/releases)
[![Stars](https://img.shields.io/github/stars/sarbagyastha/youtube_player_flutter?color=deeppink)](https://github.com/sarbagyastha/youtube_player_flutter)
[![Top Language](https://img.shields.io/github/languages/top/sarbagyastha/youtube_player_flutter?color=9cf)](https://github.com/sarbagyastha/youtube_player_flutter)
[![effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://dart.dev/guides/language/effective-dart)


Flutter plugin for playing or streaming YouTube videos inline using the official [**iFrame Player API**](https://developers.google.com/youtube/iframe_api_reference).

Supported Platforms:
* **Android** 
* **iOS**
For web support, use [youtube_player_iframe](https://pub.dev/packages/youtube_player_iframe). In future, this package will extend youtube_player_iframe.

![DEMO](misc/ypf_demo.gif)

## Salient Features
* Inline Playback
* Supports captions
* No need for API Key
* Supports custom controls
* Retrieves video meta data
* Supports Live Stream videos
* Supports changing playback rate
* Support for both Android and iOS
* Adapts to quality as per the bandwidth
* Fast Forward and Rewind on horizontal drag
* Fit Videos to wide screens with pinch gestures

The plugin uses [flutter_inappwebview](https://pub.dartlang.org/packages/flutter_inappwebview) under-the-hood.

Since *flutter_inappwebview* relies on Flutter's mechanism for embedding Android and iOS views, this plugin might share some known issues tagged with the [platform-views](https://github.com/flutter/flutter/labels/a%3A%20platform-views) label.

## Requirements
* Android: `minSdkVersion 17` and add support for `androidx` (see [AndroidX Migration](https://flutter.dev/docs/development/androidx-migration))
* iOS: `--ios-language swift`, Xcode version `>= 11`

## Setup

### iOS
No Configuration Needed

For more info, [see here](https://pub.dev/packages/flutter_inappwebview#important-note-for-ios)

### Android
Set `minSdkVersion` of your `android/app/build.gradle` file to at least 17.

For more info, [see here](https://pub.dev/packages/flutter_inappwebview#important-note-for-android)

*Note:* Although the minimum to be set is 17, the player won't play on device with API < 20 (19 if Hybrid Composition is enabled). 
For API < 20 devices, you might want to forward the video to be played using YouTube app instead, using packages like `url_launcher` or `android_intent`.

#### Using Youtube Player
         
```dart
YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: 'iLnmTe5Q2Qw',
    flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: true,
    ),
);

YoutubePlayer(
    controller: _controller,
    showVideoProgressIndicator: true,
    progressIndicatorColor: Colors.amber,
    progressColors: const ProgressBarColors(
      playedColor: Colors.amber,
      handleColor: Colors.amberAccent,
    ),
    onReady: () {
      _controller.addListener(listener);
    },
),
```

#### For FullScreen Support
If fullscreen support is required, wrap your player with `YoutubePlayerBuilder`

```dart
YoutubePlayerBuilder(
    player: YoutubePlayer(
        controller: _controller,
    ),
    builder: (context, player){
        return Column(
            children: [
                // some widgets
                player,
                //some other widgets
            ],
        );
    ),
),
```

         
#### Playing live stream videos
Set the isLive property to true in order to change the UI to match Live Video.

![Live UI Demo](misc/live_ui.png) 

```dart
YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: 'iLnmTe5Q2Qw',
    flags: YoutubePLayerFlags(
      isLive: true,
    ),
);

YoutubePlayer(
    controller: _controller,
    liveUIColor: Colors.amber,
),
```

## Want to customize the player?
 With v5.x.x and up, use the `topActions` and `bottomActions` properties to customize the player.

 Some of the widgets bundled with the plugin are:
 * FullScreenButton
 * RemainingDuration
 * CurrentPosition
 * PlayPauseButton
 * PlaybackSpeedButton
 * ProgressBar

```dart
YoutubePlayer(
    controller: _controller,
    bottomActions: [
      CurrentPosition(),
      ProgressBar(isExpanded: true),
      TotalDuration(),
    ],
),
```

## Want to play using Youtube URLs ? 
The plugin also provides `convertUrlToId()` method that converts youtube links to its corresponding video ids.
```dart
String videoId;
videoId = YoutubePlayer.convertUrlToId("https://www.youtube.com/watch?v=BBAyRBTfsOU");
print(videoId); // BBAyRBTfsOU
```

## Example

[Detailed Example](https://github.com/sarbagyastha/youtube_player_flutter/tree/master/packages/youtube_player_flutter/example)

## Quick Links
* [YoutubePlayer](https://pub.dev/documentation/youtube_player_flutter/latest/youtube_player_flutter/YoutubePlayer-class.html)
* [YoutubePlayerController](https://pub.dev/documentation/youtube_player_flutter/latest/youtube_player_flutter/YoutubePlayerController-class.html)
* [YoutubePlayerFlags](https://pub.dev/documentation/youtube_player_flutter/latest/youtube_player_flutter/YoutubePlayerFlags-class.html)
* [YoutubePlayerValue](https://pub.dev/documentation/youtube_player_flutter/latest/youtube_player_flutter/YoutubePlayerValue-class.html)
* [YoutubeMetaData](https://pub.dev/documentation/youtube_player_flutter/latest/youtube_player_flutter/YoutubeMetaData-class.html)

## Download
Download APKs from above(in badge) and try the plugin.
APKs are available in Assets of Github release page.

## Limitation 
Since the plugin is based on platform views. This plugin requires Android API level 20 or greater.


## License

```
Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```