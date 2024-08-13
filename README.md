<p align="center">
<img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/master/packages/youtube_player_iframe/screenshots/logo.png" height="100" alt="Youtube Player iFrame" />
</p>
<h2 align="center">Youtube Player iFrame</h2>


<p align="center">
<a href="https://pub.dartlang.org/packages/youtube_player_iframe"><img src="https://img.shields.io/pub/v/youtube_player_iframe" alt="Pub"></a>
<a href="https://youtube.sarbagyastha.com.np"><img src="https://img.shields.io/badge/Web-Demo-deeppink.svg" alt="Web Demo"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter/blob/master/packages/youtube_player_iframe/LICENSE"><img src="https://img.shields.io/badge/License-BSD--3-blueviolet" alt="BSD-3 License"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter"><img src="https://img.shields.io/github/languages/top/sarbagyastha/youtube_player_flutter?color=9cf" alt="Top Language"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter/issues"><img src="https://img.shields.io/github/issues/sarbagyastha/youtube_player_flutter" alt="GitHub issues"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter"><img src="https://img.shields.io/github/stars/sarbagyastha/youtube_player_flutter" alt="Stars"></a>
</p>

---

Flutter plugin for seamlessly playing or streaming YouTube videos inline using the official [**iFrame Player API**](https://developers.google.com/youtube/iframe_api_reference). This package offers extensive customization by exposing nearly the full range of the iFrame Player API's features, ensuring complete flexibility and control.

<a href="https://youtube.sarbagyastha.com.np"><img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/master/packages/youtube_player_iframe/screenshots/demo.png" width="200" alt="Demo Screenshot"></a>


## Features 🌟
- ▶️ **Inline Playback**: Provides seamless inline video playback within your app.
- 🎬 **Caption Support**: Fully supports captions for enhanced accessibility.
- 🔑 **No API Key Required**: Easily integrates without the need for an API key.
- 🎛️ **Custom Controls**: Offers extensive support for custom video controls.
- 📊 **Metadata Retrieval**: Capable of retrieving detailed video metadata.
- 📡 **Live Stream Support**: Compatible with live streaming videos.
- ⏩ **Adjustable Playback Rate**: Allows users to change the playback speed.
- 🛠️ **Custom Control Builders**: Exposes builders for creating bespoke video controls.
- 🎵 **Playlist Support**: Supports both custom playlists and YouTube's native playlist feature.
- 📱 **Fullscreen Gestures**: Enables fullscreen gestures, such as swiping up or down to enter or exit fullscreen mode.


This package uses [webview_flutter](https://pub.dev/packages/webview_flutter) under-the-hood.

## Setup
See [**webview_flutter**'s doc](https://pub.dev/packages/webview_flutter) for the requirements.

### Using the player
Start by creating a controller.

```dart
final _controller = YoutubePlayerController(
  params: YoutubePlayerParams(
    mute: false,
    showControls: true,
    showFullscreenButton: true,
  ),
);

_controller.loadVideoById(...); // Auto Play
_controller.cueVideoById(...); // Manual Play
_controller.loadPlaylist(...); // Auto Play with playlist
_controller.cuePlaylist(...); // Manual Play with playlist

// If the requirement is just to play a single video.
final _controller = YoutubePlayerController.fromVideoId(
  videoId: '<video-id>',
  autoPlay: false,
  params: const YoutubePlayerParams(showFullscreenButton: true),
);
```

Then the player can be used in two ways:

#### Using `YoutubePlayer`
This widget can be used when fullscreen support is not required.

```dart
YoutubePlayer(
  controller: _controller,
  aspectRatio: 16 / 9,
);

```

#### Using `YoutubePlayerScaffold`
This widget can be used when fullscreen support for the player is required.

```dart
YoutubePlayerScaffold(
  controller: _controller,
  aspectRatio: 16 / 9,
  builder: (context, player) {
    return Column(
      children: [
        player,
        Text('Youtube Player'),
      ],
    );
  },
)
```

See the [example app](example/lib/main.dart) for detailed usage.

## Inherit the controller to descendant widgets
The package provides `YoutubePlayerControllerProvider`.

```dart
YoutubePlayerControllerProvider(
  controller: _controller,
  child: Builder(
    builder: (context){
      // Access the controller as: 
      // `YoutubePlayerControllerProvider.of(context)` 
      // or `controller.ytController`.
    },
  ),
);
```

## Want to customize the player?
The package provides `YoutubeValueBuilder`, which can be used to create any custom controls.

For example, let's create a custom play pause button.
```dart
YoutubeValueBuilder(
   controller: _controller, // This can be omitted, if using `YoutubePlayerControllerProvider`
   builder: (context, value) {
      return IconButton(
         icon: Icon( 
           value.playerState == PlayerState.playing
             ? Icons.pause
             : Icons.play_arrow,
         ),
         onPressed: value.isReady
            ? () {
              value.playerState == PlayerState.playing
                ? context.ytController.pause()
                : context.ytController.play();
              }
            : null,
      );
   },
);
```

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->