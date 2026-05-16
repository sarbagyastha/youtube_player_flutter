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

🎬 **Embed YouTube videos in your Flutter app** — inline, silky smooth, and with zero API key hassle. Powered by the official [iFrame Player API](https://developers.google.com/youtube/iframe_api_reference), this plugin gives you near-complete control over playback without any of the headaches.

<a href="https://youtube.sarbagyastha.com.np"><img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player_iframe/screenshots/demo.png" width="200" alt="Demo Screenshot"></a>

---

## ✨ Features

| 🎯 | What it does |
|---|---|
| 📺 **Inline Playback** | Videos play right inside your app — no pop-outs, no surprises |
| 🔑 **No API Key** | Just plug and play. Seriously, no keys needed |
| 💬 **Caption Support** | Full subtitle/caption support for accessibility |
| 🎮 **Custom Controls** | Build your own UI with `YoutubeValueBuilder` |
| 📊 **Metadata Retrieval** | Fetch detailed info about any video |
| 🔴 **Live Stream Support** | Works with live streams too |
| ⏩ **Adjustable Playback Speed** | Slow-mo or 2× speed — your call |
| 📋 **Playlist Support** | Native YouTube playlists + custom ones |
| 🖥️ **Smooth Fullscreen** | Auto-enters on landscape rotation, swipe up/down gesture support |
| 🖼️ **Lazy Thumbnail Widget** | Shows a thumbnail first, creates the WebView only on tap — perfect for lists |
| 🕵️ **Privacy-Enhanced Mode** | Uses `youtube-nocookie.com` by default so YouTube doesn't track your users |
| 🌐 **Multi-Platform** | Android, iOS, macOS, and Web — all covered |

> 💡 Under the hood, this package uses [webview_flutter](https://pub.dev/packages/webview_flutter).

---

## 🛠️ Setup

Before diving in, check out the [**webview_flutter docs**](https://pub.dev/packages/webview_flutter) for any platform-specific setup (Android permissions, iOS config, etc.).

---

## 🚀 Quick Start

### 1️⃣ Create a controller

```dart
final _controller = YoutubePlayerController(
  params: YoutubePlayerParams(
    mute: false,
    showControls: true,
    showFullscreenButton: true,
    privacyEnhancedMode: true, // uses youtube-nocookie.com (default)
  ),
);

_controller.loadVideoById(videoId: '<video-id>');  // ▶️ auto-play
_controller.cueVideoById(videoId: '<video-id>');   // ⏸️ ready but paused
_controller.loadPlaylist(list: [...]);             // ▶️ auto-play playlist
_controller.cuePlaylist(list: [...]);              // ⏸️ playlist, paused
```

> 🍬 **Shortcut:** For a single video, use the convenience constructor:

```dart
final _controller = YoutubePlayerController.fromVideoId(
  videoId: '<video-id>',
  autoPlay: false,
  params: const YoutubePlayerParams(showFullscreenButton: true),
);
```

### 2️⃣ Drop the player in your widget tree

No wrapper widgets, no special scaffolding — just drop it in and go. Fullscreen is handled internally. 🎉

```dart
YoutubePlayer(
  controller: _controller,
  aspectRatio: 16 / 9,
  autoFullScreen: true, // 📱 auto-enters fullscreen on landscape rotation
)
```

### 3️⃣ Clean up when done

```dart
@override
void dispose() {
  _controller.close();
  super.dispose();
}
```

---

## 🖥️ Fullscreen

Fullscreen is smooth and just works on all platforms. The player intercepts the fullscreen button and handles the whole transition inside Flutter.

| 🎬 Trigger | 🔀 What happens |
|---|---|
| Tap fullscreen button | Animates to fullscreen |
| Rotate device to landscape | Auto-enters fullscreen (`autoFullScreen: true`) |
| Swipe up in player | Enters fullscreen |
| Swipe down in fullscreen | Exits fullscreen |
| Back button / system gesture | Exits fullscreen |

---

## 🖼️ Lazy Thumbnail (Great for Lists!)

Got a list of videos? Don't create a WebView for every item — that's expensive! 💸

`YoutubePlayerThumbnail` shows a crisp thumbnail image and only spins up the WebView when the user taps. Smooth scrolling, happy users. 😊

```dart
YoutubePlayerThumbnail(
  controller: YoutubePlayerController.fromVideoId(videoId: '<video-id>'),
  aspectRatio: 16 / 9,
  thumbnailQuality: ThumbnailQuality.high,
  thumbnailFormat: ThumbnailFormat.webp,
  // Optional: bring your own play icon 🎨
  // playIcon: const Icon(Icons.play_circle, size: 64, color: Colors.white),
)
```

Need just the thumbnail URL? No problem:

```dart
final url = YoutubePlayerController.getThumbnail(
  videoId: '<video-id>',
  quality: ThumbnailQuality.high,
  format: ThumbnailFormat.webp,
);
```

---

## 🌲 Expose the Controller Down the Tree

Use `YoutubePlayerControllerProvider` to make the controller available to any descendant widget via `context.ytController`. No prop drilling needed! 🙌

```dart
YoutubePlayerControllerProvider(
  controller: _controller,
  child: Scaffold(
    body: Column(
      children: [
        YoutubePlayer(controller: _controller),
        const Controls(), // 🎛️ can call context.ytController inside
      ],
    ),
  ),
);
```

---

## 🎛️ Custom Controls

`YoutubeValueBuilder` rebuilds whenever the player state changes — making it super easy to build any custom playback control you dream up.

```dart
YoutubeValueBuilder(
  controller: _controller, // omit if using YoutubePlayerControllerProvider
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

## ⚙️ Player Parameters

Tweak everything to match your app's vibe:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `mute` | `bool` | `false` | 🔇 Start muted |
| `showControls` | `bool` | `true` | 🎮 Show YouTube's built-in controls |
| `showFullscreenButton` | `bool` | `false` | ⛶ Show YouTube's fullscreen button |
| `privacyEnhancedMode` | `bool` | `true` | 🕵️ Use `youtube-nocookie.com` |
| `loop` | `bool` | `false` | 🔁 Loop the video |
| `strictRelatedVideos` | `bool` | `false` | 📌 Related videos from same channel only |
| `enableCaption` | `bool` | `true` | 💬 Show captions by default |
| `captionLanguage` | `String` | `'en'` | 🌍 Caption language (ISO 639-1) |
| `interfaceLanguage` | `String` | `'en'` | 🌐 Player UI language (ISO 639-1) |
| `color` | `String` | `'white'` | 🎨 Progress bar colour (`'red'` or `'white'`) |
| `enableKeyboard` | `bool` | web only | ⌨️ Keyboard shortcuts |
| `playsInline` | `bool` | `true` | 📱 Inline playback on iOS |
| `userAgent` | `String?` | `null` | 🤖 Custom WebView user agent |
| `pointerEvents` | `PointerEvents` | `initial` | 👆 CSS pointer-events on the player |
| `origin` | `String?` | `null` | 🔒 Security origin for the iFrame API |

Use `copyWith` to tweak an existing config without rebuilding from scratch:

```dart
final params = const YoutubePlayerParams(showControls: false);
final updated = params.copyWith(mute: true);
```

---

## 🔄 Migrating from `YoutubePlayerScaffold`

`YoutubePlayerScaffold` is deprecated — `YoutubePlayer` handles fullscreen on its own now. Here's how to update:

```dart
// ❌ Before (old way)
YoutubePlayerScaffold(
  controller: _controller,
  builder: (context, player) {
    return Scaffold(
      body: Column(children: [player, const Controls()]),
    );
  },
)

// ✅ After (new way)
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

---

## 🧪 Try the Example App

See everything in action — check out the [example app](example/lib/main.dart) for complete working code.

---

## 🤝 Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
