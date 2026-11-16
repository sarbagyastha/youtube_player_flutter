# youtube_player

Play YouTube videos inline with the official
[IFrame Player API](https://developers.google.com/youtube/iframe_api_reference).

This package is the plain player: it draws no Flutter UI of its own, and it
gives you one hook for your own controls. It is the planned successor to
`youtube_player_iframe`.

- **Small native hosts.** On Android, iOS and macOS the player runs in a plain
  system WebView driven over [Pigeon](https://pub.dev/packages/pigeon). There
  is no `webview_flutter` dependency.
- **Web and Wasm.** On the web, `YT.Player` is driven directly through
  `dart:js_interop`. It works with `--wasm`, and with cross-origin isolated
  pages via `webCredentialless`.
- **System fullscreen.** The player's fullscreen button uses the platform's
  own fullscreen: WebKit on iOS/macOS, a custom view on Android, the browser
  on the web. There is no Flutter-side re-parenting.
- **Client identity is set for you.** The embed is loaded with your app id as
  Referer and origin, as YouTube
  [requires](https://developers.google.com/youtube/terms/required-minimum-functionality#embedded-player-api-client-identity).
  This avoids error 153.
- **Cheap state.** Position, volume, rate and metadata are pushed by the
  player and cached, so the common getters never round-trip. Paused players
  send no traffic at all.

| Android | iOS | macOS | Web |
|:-:|:-:|:-:|:-:|
| ✅ | ✅ | ✅ | ✅ (JS & Wasm) |

## Usage

```dart
final controller = YoutubePlayerController.fromVideoId(
  videoId: 'M7lc1UVf-VE',
  autoPlay: true,
  params: const YoutubePlayerParams(mute: true),
);

// In build():
YoutubePlayer(controller: controller);

// Later:
await controller.seekTo(seconds: 30, allowSeekAhead: true);
controller.videoStateStream.listen((state) => print(state.position));

// When done:
await controller.close();
```

Read state with `YoutubeValueBuilder`, or provide the controller to a subtree
with `YoutubePlayerControllerProvider` and read it via `context.ytController`.

### Custom UI

Pass `controlsBuilder` to replace YouTube's controls with Flutter widgets:

```dart
YoutubePlayer(
  controller: controller,
  controlsBuilder: (context, value) => MyControls(value),
);
```

You don't need to set any params. With a `controlsBuilder`, the player is
created with its native controls, keyboard shortcuts and fullscreen button
turned off, and the iframe ignores pointer events, so every tap reaches your
overlay. The overlay covers exactly the player's `aspectRatio` box. It
rebuilds on every value change, and `context.ytController` works inside it.

- The controls are fixed when the player is created, so decide on
  `controlsBuilder` before the player is first shown.
- The overlay is not shown in native fullscreen. A custom fullscreen button
  can call `enterFullScreen()` on Android, macOS and the web; iPhone only
  allows the player's own button.
- For thumbnails, use `YoutubePlayerController.getThumbnail(videoId: ...)`.

### Autoplay

`fromVideoId(autoPlay: true)` waits until at least half of the player is on
screen, and only one player autoplays at a time. This follows YouTube's
Required Minimum Functionality. Set `YoutubePlayer.autoPlayWhenVisible: false`
to start immediately instead.

### Fullscreen

The fullscreen button (`showFullscreenButton`, on by default) uses the
platform's own fullscreen. `controller.value.isFullScreen` and
`setFullScreenListener` reflect it.

`enterFullScreen()` returns whether the platform accepted the request. Some
platforms only allow fullscreen from a user gesture, and iPhone only allows it
from the player's own button. On Android, `YoutubePlayerParams.fullscreenOrientation`
controls rotation.

### Links

When the user taps the title, logo, channel or a share link, the link opens
externally. A related or end-screen video loads in place instead. Pass
`onLinkTap` to handle links yourself.

## Setup

- **Android:** nothing to do. The plugin declares `INTERNET`.
- **macOS:** enable `com.apple.security.network.client` in your entitlements.
- **Web with `--wasm` multithreading (COOP/COEP headers):** set
  `YoutubePlayerParams(webCredentialless: true)`.
- **Custom client identity:** set `YoutubePlayerParams(appId: 'com.example.app')`.
  It defaults to the Android application id or Apple bundle id.

## Migrating from youtube_player_iframe

Most code only needs the import changed to `package:youtube_player/youtube_player.dart`.

| youtube_player_iframe | youtube_player |
|---|---|
| `controller.webViewController`, `package:youtube_player_iframe/webview.dart` | Removed; there is no `webview_flutter`. |
| `onWebResourceError` | `onLoadError(YoutubeLoadError)` |
| `YoutubePlayerScaffold`, orientation lists, `autoFullScreen`, `enableFullScreenOnVerticalDrag` | Removed; fullscreen is native. |
| `value.fullScreenOption.enabled` | `value.isFullScreen` |
| `enterFullScreen({lock})` | `Future<bool> enterFullScreen()` |
| `YoutubePlayer(userAgent:)` | `YoutubePlayerParams(userAgent:)` |
| `YoutubePlayerParams(color: 'white')` | `color: .white` (`ProgressBarColor`) |
| `YoutubePlayerParams(enableJavaScript:)` | Removed (always on). |
| `cuePlaylist(list:, listType: ListType.playlist)` | `ListType` has `playlist` and `userUploads` (`search` was removed by YouTube). |
| `getCurrentPositionStream()` | `videoStateStream` |
| `YoutubeError.sameAsNotEmbeddable*` | Merged into `notEmbeddable`; new `missingClientIdentity` (153). |
| `showFullscreenButton` defaulted to `false` | Defaults to `true`. |
| `YoutubePlayerThumbnail` / player thumbnail placeholder | Removed; build one with `getThumbnail`. |
| `showControls: false` + `pointerEvents: none` for custom controls | Pass `YoutubePlayer(controlsBuilder:)`; it sets both. |
| Player created on the first controller call | Created when a `YoutubePlayer` first shows it; earlier calls are queued. |

New in this package: `setCaptionsFontSize`, `reloadCaptions`, `getOptions`,
`sphericalProperties` / `setSphericalProperties`, `apiChangeStream`,
`value.isAutoplayBlocked`, `value.isReady`.
