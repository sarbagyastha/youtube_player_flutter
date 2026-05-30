<p align="center">
<img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player_iframe/screenshots/logo.png" height="100" alt="Youtube Player Flutter" />
</p>

<h2 align="center">Youtube Player Flutter</h2>

<p align="center">
A Flutter monorepo for seamless YouTube video playback powered by the official <a href="https://developers.google.com/youtube/iframe_api_reference"><strong>iFrame Player API</strong></a>.
</p>

<p align="center">
<a href="https://github.com/sarbagyastha/youtube_player_flutter"><img src="https://img.shields.io/github/stars/sarbagyastha/youtube_player_flutter?color=deeppink" alt="Stars"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter/issues"><img src="https://img.shields.io/github/issues/sarbagyastha/youtube_player_flutter" alt="GitHub issues"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter"><img src="https://img.shields.io/github/languages/top/sarbagyastha/youtube_player_flutter?color=9cf" alt="Top Language"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-BSD--3-blueviolet" alt="BSD-3 License"></a>
</p>

---

## Packages

This monorepo contains three packages:

| Package | Version | Description | Platforms |
|---|---|---|---|
| [youtube_player_flutter](packages/youtube_player_flutter) | [![pub](https://img.shields.io/pub/v/youtube_player_flutter.svg)](https://pub.dev/packages/youtube_player_flutter) | High-level Flutter plugin for inline YouTube playback | Android, iOS, macOS, Web |
| [youtube_player_iframe](packages/youtube_player_iframe) | [![pub](https://img.shields.io/pub/v/youtube_player_iframe.svg)](https://pub.dev/packages/youtube_player_iframe) | Flutter port of the official YouTube iFrame Player API | Android, iOS, macOS, Web |
| [youtube_player_iframe_web](packages/youtube_player_iframe_web) | [![pub](https://img.shields.io/pub/v/youtube_player_iframe_web.svg)](https://pub.dev/packages/youtube_player_iframe_web) | Web platform implementation for `youtube_player_iframe` | Web |

---

## Which package should I use?

- **Most apps** → use [`youtube_player_flutter`](packages/youtube_player_flutter) for a batteries-included experience on Android, iOS, macOS, and Web.
- **Need the full iFrame API** → use [`youtube_player_iframe`](packages/youtube_player_iframe) directly; it exposes the full iFrame API across all platforms.
- **Platform plugin authors** → [`youtube_player_iframe_web`](packages/youtube_player_iframe_web) is the web implementation consumed automatically by `youtube_player_iframe`.

---

## Features

- **Inline Playback**: seamless inline video playback within your app
- **Caption Support**: fully supports captions for enhanced accessibility
- **No API Key Required**: integrates without needing a YouTube API key
- **Custom Controls**: extensive support for custom video controls via builders
- **Metadata Retrieval**: retrieve detailed video metadata
- **Live Stream Support**: compatible with live streaming videos
- **Adjustable Playback Rate**: allow users to change playback speed
- **Playlist Support**: supports custom playlists and YouTube's native playlist feature
- **Fullscreen Gestures**: swipe up/down to enter or exit fullscreen

---

## Quick Start (`youtube_player_iframe`)

### Setup

See [**webview_flutter**'s docs](https://pub.dev/packages/webview_flutter) for platform requirements.

### Create a controller

```dart
final _controller = YoutubePlayerController(
  params: YoutubePlayerParams(
    mute: false,
    showControls: true,
    showFullscreenButton: true,
  ),
);

_controller.loadVideoById(...); // Auto play
_controller.cueVideoById(...);  // Manual play
_controller.loadPlaylist(...);  // Auto play with playlist
_controller.cuePlaylist(...);   // Manual play with playlist

// Single video shorthand
final _controller = YoutubePlayerController.fromVideoId(
  videoId: '<video-id>',
  autoPlay: false,
  params: const YoutubePlayerParams(showFullscreenButton: true),
);
```

### Embed the player

**`YoutubePlayer`**: use when fullscreen is not required:

```dart
YoutubePlayer(
  controller: _controller,
  aspectRatio: 16 / 9,
);
```

**`YoutubePlayerScaffold`**: use when fullscreen support is required:

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

### Inherit the controller

```dart
YoutubePlayerControllerProvider(
  controller: _controller,
  child: Builder(
    builder: (context) {
      // Access via YoutubePlayerControllerProvider.of(context)
      // or context.ytController
    },
  ),
);
```

### Custom controls

Use `YoutubeValueBuilder` to build any custom control:

```dart
YoutubeValueBuilder(
  controller: _controller, // omit when using YoutubePlayerControllerProvider
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

---

## Demo

<a href="https://youtube.sarbagyastha.com.np">
  <img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player_iframe/screenshots/demo.png" width="220" alt="Web Demo Screenshot">
</a>

[**Live Web Demo →**](https://youtube.sarbagyastha.com.np)

---

## License

BSD-3-Clause, see [LICENSE](LICENSE) for details.

---

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
