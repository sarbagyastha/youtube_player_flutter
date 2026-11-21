## 0.1.3

**November 21, 2026**

- Fix a crash on hot restart while a video is playing; players from the previous isolate are now torn down instead of calling back into it.
- Fix the video being off-center and cropped in landscape fullscreen on notched iPhones; the WebView no longer applies safe-area insets (Flutter owns the layout).

## 0.1.2

**November 17, 2026**

- Improve pub score.
- Require `youtube_player_platform_interface: ^0.1.2`.

## 0.1.1

**November 16, 2026**

- Add a minimal example.

## 0.1.0

**November 16, 2026**

- Injects the frame script into the player iframe (`WKUserScript`) to hide player UI elements and intercept clicks.
- Initial preview: WKWebView host for youtube_player on iOS and macOS with system fullscreen.
- Talks to Dart through Pigeon Native Interop (FFI) instead of platform channels; one synchronous call creates and loads a player.
- Swift Package Manager only; there is no CocoaPods podspec.
