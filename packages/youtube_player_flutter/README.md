<p align="center">
<img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player_flutter/misc/ypf.webp" width="250" alt="Youtube Player Flutter" />
</p>

<h2 align="center">Youtube Player Flutter</h2>

<p align="center">
A batteries-included YouTube player for Flutter. Drop it in and get a fully working player (controls, gestures, fullscreen, and more) with just a few lines of code.
</p>

<p align="center">
<a href="https://pub.dev/packages/youtube_player_flutter"><img src="https://img.shields.io/pub/v/youtube_player_flutter.svg" alt="pub"></a>
<a href="https://yt.sarbagyastha.com.np"><img src="https://img.shields.io/badge/Web-Demo-deeppink.svg" alt="Web Demo"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter"><img src="https://img.shields.io/github/stars/sarbagyastha/youtube_player_flutter?color=deeppink" alt="Stars"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-BSD--3-blueviolet" alt="BSD-3 License"></a>
</p>

---

## Features

- Built-in Material-style controls (play/pause, seek bar, speed, fullscreen)
- Drag left/right to seek (Android, iOS, macOS)
- Swipe up/down or rotate to landscape for fullscreen (Android, iOS)
- Customisable look via `YoutubePlayerTheme`
- Replace the default overlay with your own UI via `builder`
- Playlist previous/next when a playlist is loaded
- Lazy thumbnails for lists via `YoutubePlayerThumbnail`
- Live streams play without a special flag (no dedicated live UI)
- No YouTube API key required
- Supports Android, iOS, macOS, and Web

> Built on top of [youtube_player_iframe](https://pub.dev/packages/youtube_player_iframe). If you need direct access to the iFrame API or want to build a fully custom UI from scratch, use that package instead.

Requires Flutter `>=3.38.0` and Dart `^3.10.0`.

---

## Installation

```
flutter pub add youtube_player_flutter
```

Check [webview_flutter's setup guide](https://pub.dev/packages/webview_flutter) for any platform-specific configuration.

---

## Quick Start

### 1. Create a controller

```dart
final controller = YoutubePlayerController.fromVideoId(
  videoId: '<video-id>',
  autoPlay: true,
  startSeconds: 0,
  params: const YoutubePlayerParams(
    mute: false,
    strictRelatedVideos: true,
  ),
);
```

`fromVideoId` also accepts optional `endSeconds`. Have a YouTube URL instead of a video ID? Use the helper:

```dart
final videoId = YoutubePlayerController.convertUrlToId(
  'https://www.youtube.com/watch?v=BBAyRBTfsOU',
); // → 'BBAyRBTfsOU'
```

### 2. Add the player widget

```dart
YoutubePlayer(controller: controller)
```

Optional parameters include `aspectRatio` (default `16/9`), `autoHideDuration`, `keepAlive`, `backgroundColor`, and `gestureRecognizers`.

On Android, iOS, and macOS the package draws a custom controls overlay and hides YouTube's native controls. On Web, Flutter overlays do not receive gestures through the iframe, so the player keeps YouTube's native controls and fullscreen button.

### 3. Dispose when done

```dart
@override
void dispose() {
  controller.close();
  super.dispose();
}
```

---

## Fullscreen

On **Android and iOS**, fullscreen works automatically — no scaffold wrapper is required. The player handles the transition internally via an overlay.

| Action | Result |
|---|---|
| Tap the fullscreen button | Animates to fullscreen |
| Rotate device to landscape | Auto-enters fullscreen (`autoFullScreen: true`) |
| Swipe up on the player | Enters fullscreen (`enableFullScreenOnVerticalDrag: true`) |
| Swipe down in fullscreen | Exits fullscreen |
| Back button / system gesture | Exits fullscreen |

Disable either behaviour on the widget if needed:

```dart
YoutubePlayer(
  controller: controller,
  autoFullScreen: false,
  enableFullScreenOnVerticalDrag: false,
)
```

On **macOS**, the custom controls overlay (including the fullscreen button) is drawn, but overlay fullscreen is mobile-only — tapping the fullscreen button does not expand the player (use the host window / OS fullscreen instead). Swipe-to-fullscreen and rotation auto-fullscreen are also mobile-only. On **Web**, use YouTube's native fullscreen button.

---

## Theming

Apply `YoutubePlayerTheme` via `ThemeData.extensions` to override the default control colours and text styles:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const [
      YoutubePlayerTheme(
        progressBarActiveColor: Colors.red,
        controlsColor: Colors.white,
      ),
    ],
  ),
  home: MyHomePage(),
)
```

Available properties for the default overlay: `progressBarActiveColor`, `progressBarBufferedColor`, `progressBarBackgroundColor`, `controlsColor`, `controlsBackgroundGradient`, `timerStyle`. Unset values fall back to the app's `ColorScheme` / `TextTheme`. You can also set `titleStyle` on `YoutubePlayerTheme` for custom UIs (the default overlay does not show a title).

---

## Custom Controls

Pass a `builder` to replace the default overlay. You receive a `player` widget and the controller:

```dart
YoutubePlayer(
  controller: controller,
  builder: (context, player, ctrl) => Stack(
    children: [
      player,
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: MyControls(controller: ctrl),
      ),
    ],
  ),
)
```

On Android and iOS, `player` is a full-size placeholder — the video WebView is already behind the overlay. Layer your controls in the `Stack` as usual. On macOS, `player` is the real video surface. On Web, the default Material overlay is skipped (native YouTube controls are kept), but `builder` is still applied — put controls beside or below the player, since Flutter widgets drawn on top of the iframe will not receive pointer events.

See [example/lib/widgets/custom_builder_demo.dart](example/lib/widgets/custom_builder_demo.dart) for a complete custom-controls example.

Use `YoutubeValueBuilder` for reactive UI that rebuilds when player state changes, and `FullscreenButton` for a ready-made fullscreen toggle:

```dart
YoutubeValueBuilder(
  controller: controller,
  builder: (context, value) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            value.playerState == PlayerState.playing
                ? Icons.pause
                : Icons.play_arrow,
          ),
          onPressed: () {
            value.playerState == PlayerState.playing
                ? controller.pauseVideo()
                : controller.playVideo();
          },
        ),
        FullscreenButton(controller: controller),
      ],
    );
  },
)
```

---

## Lazy Thumbnails

Don't spin up a WebView for every item in a list. `YoutubePlayerThumbnail` shows a static thumbnail and only creates the player when the user taps it.

```dart
YoutubePlayerThumbnail(
  controller: YoutubePlayerController.fromVideoId(videoId: '<video-id>'),
  aspectRatio: 16 / 9,
  thumbnailQuality: ThumbnailQuality.high,
  thumbnailFormat: ThumbnailFormat.webp,
)
```

Note: the player created on tap uses the iframe package's bare player (not this package's Material overlay). Prefer `YoutubePlayer` when you want the built-in controls.

Just want the thumbnail URL?

```dart
final url = YoutubePlayerController.getThumbnail(
  videoId: '<video-id>',
  quality: ThumbnailQuality.high,
  format: ThumbnailFormat.webp,
);
```

---

## Switching Videos & Playlists

Load another video on the same controller:

```dart
controller.loadVideoById(videoId: '<next-video-id>');
```

Playlist APIs from `youtube_player_iframe` are re-exported — for example `loadPlaylist`, `cuePlaylist`, `nextVideo`, and `previousVideo`. When a playlist with more than one item is active, the default overlay shows previous/next buttons.

---

## Migrating from 9.x

| 9.x | 10.x |
|---|---|
| `YoutubePlayerFlags` | `YoutubePlayerParams` |
| `YoutubePlayerController(initialVideoId: …)` | `YoutubePlayerController.fromVideoId` / `loadVideoById` |
| `controller.dispose()` | `controller.close()` |
| `play()` / `pause()` | `playVideo()` / `pauseVideo()` |
| Scaffold `YoutubePlayerBuilder` widget | Removed — fullscreen is built-in. `builder` on `YoutubePlayer` is only for custom controls |
| Modular widgets (`ProgressBar`, `PlayPauseButton`, …) | Not exported — use the default overlay or a custom `builder`. `FullscreenButton` is exported for custom UIs |
| `isLive` / live UI | Removed — live streams still play via the IFrame API |

---

## Platforms

| Platform | Support |
|---|---|
| Android | Yes |
| iOS | Yes |
| macOS | Yes |
| Web | Yes (native YouTube controls) |

Follow the [webview_flutter](https://pub.dev/packages/webview_flutter) setup guide for platform-specific requirements.

---

## Example

Try the [live web demo](https://yt.sarbagyastha.com.np) or see the [example app](example/lib/main.dart) for a complete working demo (playlist carousel, theming, and custom controls).

---

## License

BSD-3-Clause. See [LICENSE](https://github.com/sarbagyastha/youtube_player_flutter/blob/main/LICENSE) for details.

This package uses the [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference). By using this package, you agree to the [YouTube API Services Terms of Service](https://developers.google.com/youtube/terms/api-services-tos).
