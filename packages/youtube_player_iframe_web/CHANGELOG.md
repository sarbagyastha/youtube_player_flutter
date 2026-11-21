## 3.1.5
**November 21, 2026**

- **No longer maintained.** Superseded by [`youtube_player`](https://pub.dev/packages/youtube_player) (web support via [`youtube_player_html`](https://pub.dev/packages/youtube_player_html)). Please switch to `youtube_player`; [`youtube_player_flutter`](https://pub.dev/packages/youtube_player_flutter) v11+ is also built on it.

## 3.1.4
- Fixes `TypeError` and spurious handling caused by unrelated `window` messages; only messages posted by the player's iframe are now processed. Thanks to [@mtallenca](https://github.com/mtallenca) for the fix ([#1185](https://github.com/sarbagyastha/youtube_player_flutter/pull/1185)).
- Bumps dependencies.

## 3.1.3
- Makes `credentialless` iframe configurable via `WebYoutubePlayerIframeControllerCreationParams`. Defaults to `false`.

## 3.1.2
- Bumps dependencies.

## 3.1.1
- Bumps dependencies.

## 3.1.0
- Updates minimum supported SDK version to Flutter 3.24/Dart 3.5.

## 3.0.3
- Bumps dependencies.
- Removes `http` as direct dependency.

## 3.0.2
- Use `credentialless` `iframe`, to allow videos to play in pages with
  `Cross-Origin-Embedder-Policy` set.
- Require `sdk: ^3.3.0` and `flutter: '>=3.19.0'`.

## 3.0.1
- Bumps dependencies to latest version.

## 3.0.0
- Adds support for wasm.
- Bumps flutter version to `>=3.18.0-0`.
- Fixes issue using `WebViewWidget` from `webview_flutter` package, together with the package.

## 2.0.2
- Register as federated Web implementation package for `youtube_player_iframe`.

## 2.0.1
- Adds auto registration of the `WebYoutubePlayerIframePlatform` implementation.

## 2.0.0
- Fixed video playback issues.
- Bumped dependencies.

## 1.0.4
- Bumped dependencies.

## 1.0.3
- Fixed unsupported platform warning.

## 1.0.2
- Fixed the supported platform.

## 1.0.1
- Fixed the supported platform.

## 1.0.0
- Web implementation of webview_flutter plugin tailored for using with youtube_player_iframe package.
