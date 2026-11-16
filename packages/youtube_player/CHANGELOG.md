## 4.0.0-dev.1

**November 16, 2026**

- Rebuilt from scratch as a federated plugin: a minimal Pigeon-driven native WebView per platform, no `webview_flutter`.
- System WebView fullscreen: the YouTube fullscreen button now uses the platform's native fullscreen.
- Client identity (HTTP Referer / origin) is set automatically, fixing error 153.
- API mirrors `youtube_player_iframe`; see the README migration section.
- Renders only the IFrame player, with no Flutter-drawn thumbnail or placeholder. The optional `controlsBuilder` adds a Flutter overlay and turns off the native controls and pointer events automatically.
- The native player is created when a `YoutubePlayer` first shows it; earlier calls are queued.
