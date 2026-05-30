<p align="center">
<img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player_iframe/misc/ypi.webp" height="100" alt="Youtube Player iFrame" />
</p>

<h2 align="center">youtube_player_iframe</h2>

<p align="center">
Embed YouTube videos in your Flutter app with full control over playback. Powered by the official <a href="https://developers.google.com/youtube/iframe_api_reference">iFrame Player API</a>. No API key required.
</p>

<p align="center">
<a href="https://pub.dev/packages/youtube_player_iframe"><img src="https://img.shields.io/pub/v/youtube_player_iframe" alt="pub"></a>
<a href="https://youtube.sarbagyastha.com.np"><img src="https://img.shields.io/badge/Web-Demo-deeppink.svg" alt="Web Demo"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-BSD--3-blueviolet" alt="BSD-3 License"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter"><img src="https://img.shields.io/github/stars/sarbagyastha/youtube_player_flutter?color=deeppink" alt="Stars"></a>
</p>

---

## Features

- **Inline playback**: videos play inside your app, no pop-outs
- **No API key**: just plug in a video ID and go
- **Custom controls**: build your own UI with `YoutubeValueBuilder`
- **Playlists**: native YouTube playlists and custom lists
- **Lazy thumbnails**: show a thumbnail first, create the player only on tap (great for lists)
- **Fullscreen**: handles rotation, swipe gestures, and back button automatically
- **Live stream support**
- **Metadata retrieval**: title, author, duration, and more
- **Adjustable playback speed**
- **Privacy-enhanced mode**: uses `youtube-nocookie.com` by default
- **Multi-platform**: Android, iOS, macOS, and Web

> Built on [webview_flutter](https://pub.dev/packages/webview_flutter). For a ready-made player with built-in controls, see [youtube_player_flutter](https://pub.dev/packages/youtube_player_flutter).

---

## Installation

```
flutter pub add youtube_player_iframe
```

Check [webview_flutter's setup guide](https://pub.dev/packages/webview_flutter) for any platform-specific configuration.

---

## Quick Start

### 1. Create a controller

```dart
final controller = YoutubePlayerController(
  params: const YoutubePlayerParams(
    showControls: true,
    showFullscreenButton: true,
    mute: false,
  ),
);

controller.loadVideoById(videoId: '<video-id>'); // auto-play
controller.cueVideoById(videoId: '<video-id>');  // ready but paused
```

For a single video, use the shorthand constructor:

```dart
final controller = YoutubePlayerController.fromVideoId(
  videoId: '<video-id>',
  autoPlay: false,
  params: const YoutubePlayerParams(showFullscreenButton: true),
);
```

### 2. Add the player widget

```dart
YoutubePlayer(
  controller: controller,
  aspectRatio: 16 / 9,
)
```

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

Fullscreen works automatically on all platforms. The player handles the transition entirely inside Flutter with no extra configuration needed.

| Action | Result |
|---|---|
| Tap the fullscreen button | Animates to fullscreen |
| Rotate device to landscape | Auto-enters fullscreen (`autoFullScreen: true`) |
| Swipe up on the player | Enters fullscreen |
| Swipe down in fullscreen | Exits fullscreen |
| Back button / system gesture | Exits fullscreen |

---

## Lazy Thumbnails (Perfect for Lists)

Don't spin up a WebView for every item in a list; that's slow and memory-hungry. `YoutubePlayerThumbnail` shows a static thumbnail image and only creates the player when the user taps it.

```dart
YoutubePlayerThumbnail(
  controller: YoutubePlayerController.fromVideoId(videoId: '<video-id>'),
  aspectRatio: 16 / 9,
  thumbnailQuality: ThumbnailQuality.high,
  thumbnailFormat: ThumbnailFormat.webp,
)
```

Just want the thumbnail URL?

```dart
final url = YoutubePlayerController.getThumbnail(
  videoId: '<video-id>',
  quality: ThumbnailQuality.high,
  format: ThumbnailFormat.webp,
);
```

---

## Custom Controls

`YoutubeValueBuilder` rebuilds whenever the player state changes. Use it to build any playback control you need:

```dart
YoutubeValueBuilder(
  controller: controller,
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
                  ? controller.pause()
                  : controller.play();
            }
          : null,
    );
  },
)
```

---

## Sharing the Controller

Use `YoutubePlayerControllerProvider` to make the controller available anywhere in the widget tree via `context.ytController`, without passing it down manually:

```dart
YoutubePlayerControllerProvider(
  controller: controller,
  child: Scaffold(
    body: Column(
      children: [
        YoutubePlayer(controller: controller),
        const MyCustomControls(), // uses context.ytController internally
      ],
    ),
  ),
)
```

---

## Player Parameters

Customise the player behaviour via `YoutubePlayerParams`:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `mute` | `bool` | `false` | Start muted |
| `showControls` | `bool` | `true` | Show YouTube's built-in controls |
| `showFullscreenButton` | `bool` | `false` | Show YouTube's fullscreen button |
| `privacyEnhancedMode` | `bool` | `true` | Use `youtube-nocookie.com` |
| `loop` | `bool` | `false` | Loop the video |
| `enableCaption` | `bool` | `true` | Show captions |
| `captionLanguage` | `String` | `'en'` | Caption language (ISO 639-1) |
| `interfaceLanguage` | `String` | `'en'` | Player UI language (ISO 639-1) |
| `strictRelatedVideos` | `bool` | `false` | Limit related videos to same channel |
| `color` | `String` | `'white'` | Progress bar colour (`'red'` or `'white'`) |
| `playsInline` | `bool` | `true` | Inline playback on iOS |
| `userAgent` | `String?` | `null` | Custom WebView user agent |

Use `copyWith` to update an existing config:

```dart
final updated = params.copyWith(mute: true);
```

---

## Example

See the [example app](example/lib/main.dart) for a complete working demo, including playlists, custom controls, and metadata.

---

## License

BSD-3-Clause. See [LICENSE](https://github.com/sarbagyastha/youtube_player_flutter/blob/main/LICENSE) for details.
