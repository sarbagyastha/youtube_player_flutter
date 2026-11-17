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

- YouTube-styled controls drawn in Flutter: play/pause, seek bar, time, playback speed, playlist next/previous, fullscreen (YouTube's own controls on the web)
- Drag left/right on the player to seek (Android, iOS, macOS)
- Swipe up/down, or rotate the device, to enter and leave fullscreen (Android, iOS, macOS)
- Fullscreen keeps your controls on screen (Android, iOS, macOS)
- Themeable via `YoutubePlayerTheme`, or replace the controls entirely with `builder`
- No YouTube API key required
- Supports Android, iOS, macOS, and Web

> Built on top of [youtube_player](https://pub.dev/packages/youtube_player), which plays YouTube in a minimal native WebView through the official IFrame Player API. Its full API (`YoutubePlayerController`, `YoutubePlayerParams`, `YoutubeValueBuilder`, ...) is re-exported from this package. If you only need YouTube's own controls, use `youtube_player` directly.

---

## Installation

```
flutter pub add youtube_player_flutter
```

**Requirements:** Dart 3.14+ and Flutter 3.50+.

---

## Quick Start

### 1. Create a controller

```dart
final controller = YoutubePlayerController.fromVideoId(
  videoId: '<video-id>',
  autoPlay: true,
  params: const YoutubePlayerParams(mute: true),
);
```

Have a YouTube URL instead of a video ID? Use the helper:

```dart
final videoId = YoutubePlayerController.convertUrlToId(
  'https://www.youtube.com/watch?v=BBAyRBTfsOU',
); // → 'BBAyRBTfsOU'
```

### 2. Add the player widget

```dart
YoutubePlayer(controller: controller)
```

Fullscreen needs no extra setup: the built-in button, a vertical swipe, or rotating the device to landscape (Android and iOS) takes the player fullscreen, and the back button returns.

### 3. Close when done

```dart
@override
void dispose() {
  controller.close();
  super.dispose();
}
```

---

## Theming

Add a `YoutubePlayerTheme` to your `ThemeData`:

```dart
ThemeData(
  extensions: const [
    YoutubePlayerTheme(
      progressBarActiveColor: Colors.red,
      controlsColor: Colors.white,
    ),
  ],
)
```

---

## Custom Controls

Pass `builder` to replace the default controls. Lay your controls over `player` with a `Stack`; the same layout is used in fullscreen, where `player` fills the screen.

```dart
YoutubePlayer(
  controller: controller,
  builder: (context, player, controller) => Stack(
    children: [
      player,
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Row(
          children: [
            YoutubeValueBuilder(
              controller: controller,
              builder: (context, value) => IconButton(
                icon: Icon(
                  value.playerState == PlayerState.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                onPressed: value.playerState == PlayerState.playing
                    ? controller.pauseVideo
                    : controller.playVideo,
              ),
            ),
            const Spacer(),
            const FullscreenButton(),
          ],
        ),
      ),
    ],
  ),
)
```

Control fullscreen from anywhere below the player with `YoutubeFullScreen.of(context)` (`enter()`, `exit()`, `toggle()`, `isFullScreen`), or listen with `YoutubePlayer.onFullScreenChanged`.

---

## Platform Setup

- **Android:** API 24+. Nothing else to do.
- **iOS / macOS:** iOS 15+ and macOS 12+. Requires Swift Package Manager (Flutter's default); CocoaPods is not supported.
- **macOS:** enable `com.apple.security.network.client` in your entitlements.
- **Web:** works in any modern browser, including `--wasm` builds. The player uses YouTube's own controls and the browser's fullscreen there, since the browser routes pointer input and fullscreen to the YouTube iframe.

See the [youtube_player setup notes](https://pub.dev/packages/youtube_player#-1-pack-your-bags) for optional settings such as Hybrid Composition++ and the client identity (`YoutubePlayerParams.appId`).

---

## Example

Try the [live web demo](https://yt.sarbagyastha.com.np) or see the [example app](example/lib/main.dart) for a complete working demo.

---

## License

BSD-3-Clause. See [LICENSE](https://github.com/sarbagyastha/youtube_player_flutter/blob/main/LICENSE) for details.

This package uses the [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference). By using this package, you agree to the [YouTube API Services Terms of Service](https://developers.google.com/youtube/terms/api-services-tos).
