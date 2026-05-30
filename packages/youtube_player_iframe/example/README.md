# youtube_player_iframe – Example

Demonstrates the `youtube_player_iframe` package with a full interactive Flutter app. A live version is available at [youtube.sarbagyastha.com.np](https://youtube.sarbagyastha.com.np).

## What's inside

- **Player view** – `YoutubePlayer` with a seek slider (`YoutubeValueBuilder` + `videoStateStream`) and fullscreen support.
- **Info panel** – displays video title, channel, duration, playback quality, and player state using `YoutubeValueBuilder`.
- **Playback tab** – runtime controls: play, pause, stop, seek, set playback rate, mute/unmute.
- **Source tab** – load a video by ID or URL, or switch between playlist entries.
- **Video list page** – browsable playlist using `YoutubeThumbnail` for lazy-loaded thumbnails.
- **Responsive layout** – side-by-side player + controls panel on wide screens; stacked list on narrow screens.
- **Fullscreen listener** – `setFullScreenListener` callback logged to the console.

## Running the app

```sh
cd packages/youtube_player_iframe/example
flutter run
```

Supported platforms: **Android**, **iOS**, **macOS**, **Web**.
