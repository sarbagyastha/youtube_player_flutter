# Youtube Player for Flutter Example

[More Detailed Example](https://github.com/sarbagyastha/youtube_player_flutter/blob/master/example/lib/main.dart)

```dart
YoutubePlayer(
    context: context,
    videoId: "iLnmTe5Q2Qw",
    autoPlay: true,
    showVideoProgressIndicator: true,
    videoProgressIndicatorColor: Colors.amber,
    progressColors: ProgressColors(
      playedColor: Colors.amber,
      handleColor: Colors.amberAccent,
    ),
    onPlayerInitialized: (controller) {
      _controller = controller;
      _controller.addListener(listener);
    },
),
```