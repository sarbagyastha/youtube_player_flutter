<p align="center">
<img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player/misc/logo_512.png" width="120" alt="youtube_player_darwin" />
</p>

# youtube_player_darwin

The iOS and macOS implementation of [`youtube_player`](https://pub.dev/packages/youtube_player). It hosts the YouTube IFrame Player API in a minimal `WKWebView`, driven through Pigeon Native Interop (FFI, no platform channels), and uses WebKit's element fullscreen.

Requires [Swift Package Manager](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers); CocoaPods is not supported.

On macOS, Flutter plugins get no detach callback, so in apps that create and destroy several engines, players of a destroyed engine are only released on the next hot restart or app exit.

## Usage

This package is [endorsed](https://flutter.dev/to/endorsed-federated-plugin): depend on `youtube_player` and this implementation is included automatically.
