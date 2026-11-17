## 4.0.2

**November 17, 2026**

- Improve pub score.
- Require the latest platform packages (`^0.1.2`).

## 4.0.1

**November 16, 2026**

- Shorten the package description.
- Require the latest platform packages (`^0.1.1`).

## 4.0.0

**November 16, 2026**

- `elementVisibility` and `setElementVisible` to show or hide YouTube's own player UI elements (logo, title, share, more videos, ...) on Android, iOS and macOS.
- `onNavigationRequest` decides what clicks on the player UI do. It gets the clicked `PlayerElement` and can also block buttons such as share.
- Rebuilt from scratch as a federated plugin: a minimal native WebView per platform driven through Pigeon Native Interop (JNI / FFI, no platform channels), no `webview_flutter`.
- Faster first frame: the player is created and loaded in one call with its background color, and `fromVideoId(startSeconds:)` no longer loads the video twice.
- `YoutubePlayerValue.isMuted` / `volume`, so controls can react to mute and volume; `playbackRate` now follows what the player reports instead of resetting on each new video.
- Cheaper playback: progress ticks use a timer instead of a per-frame loop and skip unchanged values; Android can use Hybrid Composition++.
- System WebView fullscreen: the YouTube fullscreen button now uses the platform's native fullscreen.
- Client identity (HTTP Referer / origin) is set automatically, fixing error 153.
- API mirrors `youtube_player_iframe`; see the README migration section.
- Commands (`playVideo`, `seekTo`, `mute`, …) and `close()` return `void`, and cached state getters (`currentTime`, `volume`, `isMuted`, `playbackRate`, `playerState`, …) are synchronous, because calls go straight to native. Calls made before the player is ready are still queued in order.
- Renders only the IFrame player, with no Flutter-drawn thumbnail or placeholder. The optional `controlsBuilder` adds a Flutter overlay and turns off the native controls and pointer events automatically.
- The native player is created when a `YoutubePlayer` first shows it; earlier calls are queued.
