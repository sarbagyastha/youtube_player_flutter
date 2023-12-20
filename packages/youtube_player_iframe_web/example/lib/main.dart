import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
  runApp(const MyApp());
}

///
class MyApp extends StatelessWidget {
  ///
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Youtube Player Iframe Web Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Youtube Player Iframe Web Demo'),
        ),
        body: const Padding(
          padding: EdgeInsets.all(32),
          child: PlayerWidget(),
        ),
      ),
    );
  }
}

///
class PlayerWidget extends StatelessWidget {
  ///
  const PlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: YoutubePlayerController.fromVideoId(
        videoId: 'gCRNEJxDJKM',
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      ),
      aspectRatio: 16 / 9,
    );
  }
}
