## 4.0.0-dev.1

**November 16, 2026**

- Rebuilt from scratch as a federated plugin: a minimal native WebView per platform driven through Pigeon Native Interop (JNI / FFI, no platform channels), no `webview_flutter`.
- Faster first frame: the player is created and loaded in one call with its background color, and `fromVideoId(startSeconds:)` no longer loads the video twice.
- Cheaper playback: progress ticks use a timer instead of a per-frame loop and skip unchanged values; Android can use Hybrid Composition++.
- System WebView fullscreen: the YouTube fullscreen button now uses the platform's native fullscreen.
- Client identity (HTTP Referer / origin) is set automatically, fixing error 153.
- API mirrors `youtube_player_iframe`; see the README migration section.
- Renders only the IFrame player, with no Flutter-drawn thumbnail or placeholder. The optional `controlsBuilder` adds a Flutter overlay and turns off the native controls and pointer events automatically.
- The native player is created when a `YoutubePlayer` first shows it; earlier calls are queued.
