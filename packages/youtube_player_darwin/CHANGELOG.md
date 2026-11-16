## 0.1.0-dev.1

**November 16, 2026**

- Injects the frame script into the player iframe (`WKUserScript`) to hide player UI elements and intercept clicks.
- Initial preview: WKWebView host for youtube_player on iOS and macOS with system fullscreen.
- Talks to Dart through Pigeon Native Interop (FFI) instead of platform channels; one synchronous call creates and loads a player.
- Swift Package Manager only; there is no CocoaPods podspec.
