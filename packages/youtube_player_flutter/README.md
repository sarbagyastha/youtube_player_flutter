<p align="center">
<img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player_flutter/misc/ypf.webp" width="250" alt="Youtube Player Flutter" />
</p>

<h2 align="center">Youtube Player Flutter</h2>

<p align="center">
A batteries-included YouTube player for Flutter. Drop it in and get a fully working player (controls, gestures, live stream support, and more) with just a few lines of code.
</p>

<p align="center">
<a href="https://pub.dev/packages/youtube_player_flutter"><img src="https://img.shields.io/pub/v/youtube_player_flutter.svg" alt="pub"></a>
<a href="https://yt.sarbagyastha.com.np"><img src="https://img.shields.io/badge/Web-Demo-deeppink.svg" alt="Web Demo"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter"><img src="https://img.shields.io/github/stars/sarbagyastha/youtube_player_flutter?color=deeppink" alt="Stars"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-BSD--3-blueviolet" alt="BSD-3 License"></a>
</p>

---

## Features

- Built-in playback controls (play/pause, seek bar, duration, fullscreen)
- Drag left/right to fast-forward or rewind
- Pinch gesture to enter fullscreen
- Live stream UI with a red indicator
- Customisable top and bottom action bars
- No YouTube API key required
- Supports Android, iOS, macOS, and Web

> Built on top of [youtube_player_iframe](https://pub.dev/packages/youtube_player_iframe). If you need direct access to the iFrame API or want to build a fully custom UI, use that package instead.

---

## Installation

```
flutter pub add youtube_player_flutter
```

---

## Quick Start

### 1. Create a controller

```dart
final controller = YoutubePlayerController(
  initialVideoId: '<video-id>',
  flags: const YoutubePlayerFlags(
    autoPlay: true,
    mute: false,
  ),
);
```

Have a YouTube URL instead of a video ID? Use the helper:

```dart
final videoId = YoutubePlayer.convertUrlToId(
  'https://www.youtube.com/watch?v=BBAyRBTfsOU',
); // → 'BBAyRBTfsOU'
```

### 2. Add the player widget

```dart
YoutubePlayer(
  controller: controller,
  showVideoProgressIndicator: true,
  progressIndicatorColor: Colors.red,
)
```

### 3. Add fullscreen support

Wrap with `YoutubePlayerBuilder` to enable fullscreen:

```dart
YoutubePlayerBuilder(
  player: YoutubePlayer(controller: controller),
  builder: (context, player) {
    return Scaffold(
      body: Column(
        children: [
          player,
          // rest of your screen
        ],
      ),
    );
  },
)
```

### 4. Dispose when done

```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

---

## Live Stream Videos

Set `isLive: true` to switch the player to a live stream UI (red indicator, no seek bar):

```dart
final controller = YoutubePlayerController(
  initialVideoId: '<live-stream-id>',
  flags: const YoutubePlayerFlags(isLive: true),
);

YoutubePlayer(
  controller: controller,
  liveUIColor: Colors.red,
)
```

---

## Custom Controls

Use `topActions` and `bottomActions` to swap in your own controls. Several pre-built widgets are included:

| Widget | What it shows |
|---|---|
| `PlayPauseButton` | Play / pause toggle |
| `CurrentPosition` | Current timestamp |
| `RemainingDuration` | Time left |
| `ProgressBar` | Seek bar |
| `FullScreenButton` | Fullscreen toggle |
| `PlaybackSpeedButton` | Speed picker |

```dart
YoutubePlayer(
  controller: controller,
  bottomActions: [
    CurrentPosition(),
    ProgressBar(isExpanded: true),
    RemainingDuration(),
    FullScreenButton(),
  ],
)
```

---

## Platform Requirements

| Platform | Minimum |
|---|---|
| Android | API level 20 (`minSdkVersion 20`) |
| iOS | iOS 11, Swift, Xcode ≥ 11 |
| macOS | macOS 10.14 |
| Web | Any modern browser |

For Android and iOS setup details, see the [webview_flutter docs](https://pub.dev/packages/webview_flutter).

---

## Example

Try the [live web demo](https://yt.sarbagyastha.com.np) or see the [example app](example/lib/main.dart) for a complete working demo.

---

## License

BSD-3-Clause. See [LICENSE](https://github.com/sarbagyastha/youtube_player_flutter/blob/main/LICENSE) for details.

This package uses the [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference). By using this package, you agree to the [YouTube API Services Terms of Service](https://developers.google.com/youtube/terms/api-services-tos).
