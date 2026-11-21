<p align="center">
<img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player_flutter/misc/ypf.webp" width="250" alt="Youtube Player Flutter" />
</p>

<h2 align="center">Youtube Player Flutter</h2>

<p align="center">
<b>A batteries-included YouTube player for Flutter.</b> Drop it in and get a fully working player with controls, gestures and fullscreen in a few lines of code.<br>
⚡ Native speed, Flutter-drawn controls, and fullscreen that doesn't reload the video.
</p>

<p align="center">
<a href="https://pub.dev/packages/youtube_player_flutter"><img src="https://img.shields.io/pub/v/youtube_player_flutter.svg" alt="pub"></a>
<img src="https://img.shields.io/badge/platforms-Android%20·%20iOS%20·%20macOS%20·%20Web-0F0F12" alt="platforms">
<a href="https://yt.sarbagyastha.com.np"><img src="https://img.shields.io/badge/Web-Demo-deeppink.svg" alt="Web Demo"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter"><img src="https://img.shields.io/github/stars/sarbagyastha/youtube_player_flutter?color=deeppink" alt="Stars"></a>
<a href="https://github.com/sarbagyastha/youtube_player_flutter/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-BSD--3-blueviolet" alt="BSD-3 License"></a>
</p>

---

## 🚀 What's new in 11.0

Version 11 swaps the engine under the hood. The player now runs on
[youtube_player](https://pub.dev/packages/youtube_player): a small native
WebView per platform, driven through [Pigeon](https://pub.dev/packages/pigeon)
Native Interop (JNI on Android, FFI on iOS and macOS). There are no platform
channels, and no `webview_flutter`.

| | |
|---|---|
| ⚡ **Straight to native** | Calls go directly to the native player instead of through platform channels. Commands (`playVideo`, `seekTo`, …) return `void`, and getters (`currentTime`, `volume`, `playerState`, …) return values right away. No `await` needed. |
| 🏎️ **Faster start, lighter playback** | The player is created and loaded in one call. Progress updates run on a timer and skip unchanged values. Android can use Hybrid Composition++. |
| 📺 **Fullscreen, rebuilt** | The old overlay workaround is gone. On Android, iOS and macOS, the same native view moves into a lightweight fullscreen route, with no reload and no second WebView. The page underneath stops rendering, and your controls come along. |
| 🎞️ **Smoother controls** | The seek bar repaints instead of rebuilding and moves smoothly. The time label updates once a second. Hidden controls ignore position updates, and the buffering spinner rests while it's hidden. |
| 👀 **Polite autoplay** | `autoPlayWhenVisible` waits until at least half the player is on screen, and only one player autoplays at a time, as YouTube's Required Minimum Functionality asks. |
| 📜 **Scroll friendly** | Swiping up and down inside a scroll view scrolls the list, not the player into fullscreen. |
| 🪪 **Goodbye, error 153** | Your app's client identity is sent automatically. |

Coming from v10? Jump to [🧳 Coming from v10](#-6-coming-from-v10). The full list is in the [CHANGELOG](CHANGELOG.md).

## ✨ Features

| | |
|---|---|
| 🎛️ **YouTube-style controls** | Play/pause, seek bar, time, playback speed, playlist next/previous and fullscreen, all drawn in Flutter. The web uses YouTube's own controls. |
| 👆 **Drag to seek** | Drag left or right on the player to scrub (Android, iOS, macOS). |
| ↕️ **Swipe or rotate to fullscreen** | Swipe up, or turn the device to landscape. Swipe down or press back to return (Android, iOS, macOS). |
| 🎨 **Themeable** | Restyle the controls with `YoutubePlayerTheme`, or replace them with your own `builder`. |
| 🔑 **No API key** | Uses the official [IFrame Player API](https://developers.google.com/youtube/iframe_api_reference). |

| Android | iOS | macOS | Web |
|:-:|:-:|:-:|:-:|
| ✅ | ✅ | ✅ | ✅ |

> 💡 This package re-exports the full [youtube_player](https://pub.dev/packages/youtube_player) API (`YoutubePlayerController`, `YoutubePlayerParams`, `YoutubeValueBuilder`, …). If YouTube's own controls are all you need, or you're building a completely custom UI, use `youtube_player` directly.

---

## 🧭 The journey

1. [📦 Pack your bags](#-1-pack-your-bags): install and set up
2. [🎬 Press play](#-2-press-play): your first video
3. [🎨 Dress it up](#-3-dress-it-up): theming
4. [🎮 Bring your own controls](#-4-bring-your-own-controls): custom UI
5. [📺 Go big](#-5-go-big): fullscreen
6. [🧳 Coming from v10?](#-6-coming-from-v10): migration guide

---

## 📦 1. Pack your bags

```sh
flutter pub add youtube_player_flutter
```

**Requirements:** Dart 3.14+ and Flutter 3.50+.

Then a few platform notes:

- 🤖 **Android:** API 24+. Nothing else to do.
- 🍎 **iOS / macOS:** iOS 15+ and macOS 12+. Requires Swift Package Manager (Flutter's default). CocoaPods is not supported.
- 💻 **macOS:** enable `com.apple.security.network.client` in your entitlements.
- 🌐 **Web:** any modern browser, including `--wasm` builds. The browser sends pointer input and fullscreen to the YouTube iframe, so the web player uses YouTube's own controls and the browser's fullscreen.

✨ *Optional extras*, such as Hybrid Composition++ on Android and a custom client identity (`YoutubePlayerParams.appId`), are covered in the [youtube_player setup notes](https://pub.dev/packages/youtube_player#-1-pack-your-bags).

## 🎬 2. Press play

Create a controller:

```dart
final controller = YoutubePlayerController.fromVideoId(
  videoId: '<video-id>',
  autoPlay: true,
  params: const YoutubePlayerParams(mute: true),
);
```

🔗 Have a URL instead of a video ID? Use the helper:

```dart
final videoId = YoutubePlayerController.convertUrlToId(
  'https://www.youtube.com/watch?v=BBAyRBTfsOU',
); // → 'BBAyRBTfsOU'
```

Drop in the player:

```dart
YoutubePlayer(controller: controller)
```

And clean up when you're done:

```dart
@override
void dispose() {
  controller.close();
  super.dispose();
}
```

That's it, you're watching YouTube. 🍿

**👀 About autoplay:** `fromVideoId(autoPlay: true)` waits until at least
half of the player is on screen, and only one player autoplays at a time. Set
`YoutubePlayer(autoPlayWhenVisible: false)` to start right away instead.

## 🎨 3. Dress it up

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

## 🎮 4. Bring your own controls

Pass `builder` to replace the default controls. Lay your controls over
`player` with a `Stack`. The same layout is used in fullscreen, where
`player` fills the screen.

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

## 📺 5. Go big

Fullscreen works out of the box: tap the built-in button, swipe up, or rotate
the device to landscape (Android and iOS). Press back to return.

Under the hood, the player's existing native view moves into an opaque
fullscreen route. Nothing is recreated or reloaded, so the video keeps
playing without a hiccup, and the page underneath stops rendering while
you're away.

To control it yourself, call `YoutubeFullScreen.of(context)` from anywhere
below the player, for example inside `builder`:

```dart
final fullScreen = YoutubeFullScreen.of(context);

fullScreen.enter();      // go fullscreen
fullScreen.exit();       // back inline
fullScreen.toggle();     // flip it
fullScreen.isFullScreen; // where are we?
```

To react to changes, use the callback:

```dart
YoutubePlayer(
  controller: controller,
  onFullScreenChanged: (isFullScreen) => debugPrint('Fullscreen: $isFullScreen'),
)
```

🧩 Fine-tune it with `autoFullScreen` (rotate to enter or leave) and
`enableFullScreenOnVerticalDrag` (swipe to enter or leave). On the web,
`YoutubeFullScreen` and `FullscreenButton` use the browser's fullscreen.

---

## 🧳 6. Coming from v10?

v10 was built on `youtube_player_iframe`. v11 re-exports `youtube_player`
instead, which mirrors the same API, so most of your code carries over.
These are the parts that change:

### 🧰 Update your toolchain

- Dart `^3.14.0` and Flutter `>=3.50.0`.
- Android `minSdk 24`, iOS 15, macOS 12.
- iOS and macOS apps must use Swift Package Manager. If you're still on CocoaPods, run `flutter config --enable-swift-package-manager`.

### 🧽 Say goodbye to webview_flutter

`controller.webViewController` and `package:youtube_player_iframe/webview.dart`
are gone, because there is no `webview_flutter` anymore. Replace
`onWebResourceError` with `onLoadError`:

```dart
// v10
YoutubePlayerController(onWebResourceError: (error) => ...);

// v11
YoutubePlayerController(onLoadError: (error) => ...);
```

### 📺 Fullscreen moved to the widget tree

Fullscreen now belongs to this package rather than the controller:

```dart
// v10
controller.toggleFullScreen();
final isFullScreen = controller.value.fullScreenOption.enabled;
FullscreenButton(controller: controller);

// v11 (from below the player, e.g. inside `builder`)
YoutubeFullScreen.of(context).toggle();
final isFullScreen = YoutubeFullScreen.of(context).isFullScreen;
const FullscreenButton();
```

| v10 | v11 |
|---|---|
| `controller.enterFullScreen()` | `YoutubeFullScreen.of(context).enter()` |
| `controller.exitFullScreen()` | `YoutubeFullScreen.of(context).exit()` |
| `controller.toggleFullScreen()` | `YoutubeFullScreen.of(context).toggle()` |
| `value.fullScreenOption.enabled` | `YoutubeFullScreen.of(context).isFullScreen`, or `YoutubePlayer(onFullScreenChanged:)` |
| `FullscreenButton(controller: controller)` | `const FullscreenButton()` (it finds the enclosing player) |

> ⚠️ The controller still has `enterFullScreen()` / `toggleFullScreen()`
> from `youtube_player`, but those request the WebView's own fullscreen,
> without your Flutter controls. With this package, use `YoutubeFullScreen`.

### ⚡ Drop the `await`

Calls go straight to native now, so commands return `void` and cached state
is read synchronously:

```dart
// v10
await controller.playVideo();
await controller.seekTo(seconds: 30);
final position = await controller.currentTime;

// v11
controller.playVideo();
controller.seekTo(seconds: 30);
final position = controller.currentTime;
```

The same goes for `pauseVideo()`, `mute()`, `close()`, … and the getters
`volume`, `isMuted`, `playbackRate`, `playerState`, `duration` and
`videoLoadedFraction`. Queries such as `playlist` and `videoUrl` still
return a `Future`.

### 🔁 A few renames

<details>
<summary><b>🗺️ Full migration map</b></summary>

| v10 (`youtube_player_iframe`) | v11 (`youtube_player`) |
|---|---|
| `getCurrentPositionStream()` | `videoStateStream` |
| `YoutubePlayerParams(color: 'white')` | `color: .white` (`ProgressBarColor`) |
| `YoutubePlayerParams(enableJavaScript:)` | Removed (always on). |
| `YoutubeError.sameAsNotEmbeddable` / `sameAsNotEmbeddable2` | Merged into `notEmbeddable`. New: `missingClientIdentity` (153). |
| `YoutubePlayerThumbnail` | Removed. Build your own with `YoutubePlayerController.getThumbnail(videoId: ...)`. |
| Player created on the first controller call | Created when a `YoutubePlayer` first shows it. Earlier calls are queued. |
| `YoutubePlayerScaffold` | Removed. Fullscreen needs no wrapper. |

More details are in youtube_player's
[migration guide](https://pub.dev/packages/youtube_player#-8-coming-from-youtube_player_iframe).

</details>

### ✅ What stays the same

The `YoutubePlayer` widget keeps its parameters: `aspectRatio`, `builder`,
`autoHideDuration`, `backgroundColor`, `gestureRecognizers`, `keepAlive`,
`autoFullScreen` and `enableFullScreenOnVerticalDrag`. `YoutubePlayerTheme`,
`YoutubePlayerController.fromVideoId` and `convertUrlToId` work as before.

> 🦕 Upgrading from v9 or older (`YoutubePlayerBuilder`, `YoutubePlayerFlags`,
> `initialVideoId`)? That API was retired in v10. Start fresh from
> [🎬 Press play](#-2-press-play).

---

## 🧪 Example

Try the [live web demo](https://yt.sarbagyastha.com.np) or explore the [example app](example/lib/main.dart).

## 📄 License

BSD-3-Clause. See [LICENSE](https://github.com/sarbagyastha/youtube_player_flutter/blob/main/LICENSE) for details.

This package uses the [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference). By using this package, you agree to the [YouTube API Services Terms of Service](https://developers.google.com/youtube/terms/api-services-tos).

---

<p align="center">
🏁 <b>You made it!</b> Found a bug or have an idea?
<a href="https://github.com/sarbagyastha/youtube_player_flutter/issues">Open an issue</a> 💬
</p>
