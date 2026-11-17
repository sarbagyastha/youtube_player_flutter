## 0.1.2

**November 17, 2026**

- Improve pub score.
- Require `youtube_player_platform_interface: ^0.1.2`.

## 0.1.1

**November 16, 2026**

- Add a minimal example.

## 0.1.0

**November 16, 2026**

- Injects the frame script into the player iframe (`androidx.webkit` document-start scripts) to hide player UI elements and intercept clicks.
- Initial preview: Android WebView host for youtube_player with system fullscreen.
- Talks to Dart through Pigeon Native Interop (JNI) instead of platform channels; one synchronous call creates and loads a player.
- Uses Hybrid Composition++ when the app enables it and the device supports it.
