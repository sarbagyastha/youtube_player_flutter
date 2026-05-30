# youtube_player_iframe_web – Example

Demonstrates `youtube_player_iframe_web`, the web platform implementation for `youtube_player_iframe`.

## What's inside

- **`YoutubePlayer`** – embedded YouTube video (`YoutubePlayerController.fromVideoId`) alongside a standard `WebViewWidget` pointing to flutter.dev.
- **Side-by-side layout** – responsive row on wide screens, stacked column on narrow screens — shows that `YoutubePlayer` and `webview_flutter`'s `WebViewWidget` coexist correctly in the same Flutter web app.

> **Note:** You normally don't need to add `youtube_player_iframe_web` directly — it is pulled in automatically when you use `youtube_player_iframe` on web. This example is mainly useful for platform-implementation development and regression testing.

## Running the app

```sh
cd packages/youtube_player_iframe_web/example
flutter run -d chrome
```

Supported platforms: **Web only**.
