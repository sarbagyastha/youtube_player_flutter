import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoList extends StatefulWidget {
  @override
  _VideoListState createState() => _VideoListState();
}

class _VideoListState extends State<VideoList> {
  var videoIds = <String>[
    "BBAyRBTfsOU",
    "7QUtEmBT_-w",
    "QbSzrWYqNRg",
    "nONOGLMzXjc",
    "sf3oOx90j9Y",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video List"),
      ),
      body: ListView.separated(
        itemBuilder: (context, index) => YoutubePlayer(
              key: UniqueKey(),
              context: context,
              videoId: videoIds[index],
              autoPlay: false,
              hideFullScreenButton: true,
              showVideoProgressIndicator: true,
            ),
        separatorBuilder: (_, i) => SizedBox(
              height: 10.0,
            ),
        itemCount: videoIds.length,
      ),
    );
  }
}
