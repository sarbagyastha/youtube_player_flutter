![YOUTUBE PLAYER FLUTTER](misc/ypf_banner.png)

[![pub package](https://img.shields.io/pub/vpre/youtube_player_flutter.svg)](https://pub.dartlang.org/packages/youtube_player_flutter)
[![Build Status](https://travis-ci.org/sarbagyastha/youtube_player_flutter.svg?branch=master)](https://travis-ci.org/sarbagyastha/youtube_player_flutter)
[![licence](https://img.shields.io/badge/licence-BSD-orange.svg)](https://github.com/sarbagyastha/youtube_player_flutter/blob/master/LICENSE)
[![Download](https://img.shields.io/badge/download-APK-informational.svg)](https://github.com/sarbagyastha/youtube_player_flutter/releases)
[![Stars](https://img.shields.io/github/stars/sarbagyastha/youtube_player_flutter?color=deeppink)](https://github.com/sarbagyastha/youtube_player_flutter)
[![Top Language](https://img.shields.io/github/languages/top/sarbagyastha/youtube_player_flutter?color=9cf)](https://github.com/sarbagyastha/youtube_player_flutter)



Flutter plugin for playing or streaming YouTube videos inline using the official [**iFrame Player API**](https://developers.google.com/youtube/iframe_api_reference).
Supports both **Android** and **iOS** platforms.

![DEMO](misc/ypf_demo.gif)

## Salient Features
* Inline Playback
* Supports captions
* No need for API Key
* Supports custom controls
* Supports Live Stream videos
* Supports changing playback rate
* Support for both Android and iOS
* Adapts to quality as per the bandwidth
* Fast Forward and Rewind on horizontal drag

The plugin uses [webview_flutter](https://pub.dartlang.org/packages/webview_flutter) under-the-hood to play videos. 

Since *webview_flutter* relies on Flutter's new mechanism for embedding Android and iOS views, this plugin might share some known issues tagged with the [platform-views](https://github.com/flutter/flutter/labels/a%3A%20platform-views) and/or [webview](https://github.com/flutter/flutter/labels/p%3A%20webview) labels.


## Setup

### iOS
Opt-in to the embedded views preview by adding a boolean property to the app's `Info.plist` file
with the key `io.flutter.embedded_views_preview` and the value `YES`.

### Android
No configuration required - the plugin should work out of the box.


#### Using Youtube Player
         
```dart
YoutubePlayer(
    context: context,
    initialVideoId: "iLnmTe5Q2Qw",
    flags: YoutubePlayerFlags(
      autoPlay: true,
      showVideoProgressIndicator: true,
    ),
    videoProgressIndicatorColor: Colors.amber,
    progressColors: ProgressColors(
      playedColor: Colors.amber,
      handleColor: Colors.amberAccent,
    ),
    onPlayerInitialized: (controller) {
      _controller = controller;
      _controller.addListener(listener);
    },
),
```
         
#### Playing live stream videos
Set the isLive property to true in order to change the UI to match Live Video.

![Live UI Demo](misc/live_ui.png) 

```dart
YoutubePlayer(
    context: context,
    initialVideoId: "iLnmTe5Q2Qw",
    flags: YoutubePLayerFlags(
      isLive: true,
    ),
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
    context: context,
    initialVideoId: "iLnmTe5Q2Qw",
    bottomActions: [
      CurrentPosition(),
      ProgressBar(isExpanded: true),
      TotalDuration(),
    ],
),
```

## Didn't like the controls at all?
Don't worry, Got a solution for you. :wink:

Set the hideControls property to true, then you can create your own custom controls using the controller obtained from onPlayerInitialized property.

```dart
YoutubePlayer(
    context: context,
    initialVideoId: "iLnmTe5Q2Qw",
    flags: YoutubePlayerFlags(
      hideControls: true,
    ),
    onPlayerInitialized: (controller) {
      //Create your own UI using this controller
      //on top of the player.
    },
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

[More Detailed Example](https://github.com/sarbagyastha/youtube_player_flutter/tree/master/example)

## Note
Know more about the configuration options [here](https://pub.dartlang.org/documentation/youtube_player_flutter/latest/youtube_player_flutter/youtube_player_flutter-library.html).

## Download
Download apk from above(in badges) and try the plugin.

## Limitation 
Since the plugin is based on platform views. This plugin requires Android API level 20 or greater.

If you only want to target Android and need support for Android Kitkat or less, then you can use [youtube_player](https://pub.dartlang.org/packages/youtube_player).  

## License

```
Copyright 2019 Sarbagya Dhaubanjar. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

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