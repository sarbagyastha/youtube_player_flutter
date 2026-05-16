<p align="center">
<img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player_iframe/screenshots/logo.png" height="100" alt="Youtube Player iFrame" />
</p>
<h2 align="center">Youtube Player iFrame</h2>


<p align="center">
<a href="https://pub.dev/packages/youtube_player_iframe"><img src="https://img.shields.io/pub/v/youtube_player_iframe" alt="Pub"></a>
<a href="https://youtube.sarbagyastha.com.np"><img src="https://img.shields.io/badge/Web-Demo-deeppink.svg" alt="Web Demo"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter/blob/main/packages/youtube_player_iframe/LICENSE"><img src="https://img.shields.io/badge/License-BSD--3-blueviolet" alt="BSD-3 License"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter"><img src="https://img.shields.io/github/languages/top/sarbagyastha/youtube_player_flutter?color=9cf" alt="Top Language"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter/issues"><img src="https://img.shields.io/github/issues/sarbagyastha/youtube_player_flutter" alt="GitHub issues"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter"><img src="https://img.shields.io/github/stars/sarbagyastha/youtube_player_flutter" alt="Stars"></a>
</p>

---

Flutter plugin for seamlessly playing or streaming YouTube videos inline using the official [**iFrame Player API**](https://developers.google.com/youtube/iframe_api_reference). This package offers extensive customization by exposing nearly the full range of the iFrame Player API's features, ensuring complete flexibility and control.

<a href="https://youtube.sarbagyastha.com.np"><img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player_iframe/screenshots/demo.png" width="200" alt="Demo Screenshot"></a>


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
- 📱 **Fullscreen Support**: Flutter-side fullscreen via `OverlayPortal` with smooth animation — no `SystemChrome` calls required. Auto-enters fullscreen on landscape rotation and supports swipe-up/down gestures.


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

Then use `YoutubePlayer` directly in your widget tree. Fullscreen is handled
internally — no wrapper widget is needed.

```dart
YoutubePlayer(
  controller: _controller,
  aspectRatio: 16 / 9,
  autoFullScreen: true, // auto-enter fullscreen on landscape (default: true)
)
```

The player intercepts the YouTube fullscreen button and handles the transition
entirely on the Flutter side using `OverlayPortal`, animating the WebView to
fill the screen without any `SystemChrome` orientation calls.

See the [example app](example/lib/main.dart) for detailed usage.

## Inherit the controller to descendant widgets
Use `YoutubePlayerControllerProvider` to expose the controller to widgets
further down the tree via `context.ytController`.

```dart
YoutubePlayerControllerProvider(
  controller: _controller,
  child: Scaffold(
    body: Column(
      children: [
        YoutubePlayer(controller: _controller),
        // Descendants can now call context.ytController
        const Controls(),
      ],
    ),
  ),
);
```

## Want to customize the player?
The package provides `YoutubeValueBuilder`, which can be used to create any custom controls.

For example, let's create a custom play pause button.
```dart
YoutubeValueBuilder(
   controller: _controller, // Can be omitted when using YoutubePlayerControllerProvider
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

## Migrating from `YoutubePlayerScaffold`

`YoutubePlayerScaffold` is deprecated. `YoutubePlayer` now handles fullscreen
internally, so the scaffold wrapper is no longer needed.

```dart
// Before
YoutubePlayerScaffold(
  controller: _controller,
  builder: (context, player) {
    return Scaffold(
      body: Column(
        children: [player, const Controls()],
      ),
    );
  },
)

// After — wrap with YoutubePlayerControllerProvider only if descendant
// widgets access the controller via context.ytController.
YoutubePlayerControllerProvider(
  controller: _controller,
  child: Scaffold(
    body: Column(
      children: [
        YoutubePlayer(controller: _controller),
        const Controls(),
      ],
    ),
  ),
)
```

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
