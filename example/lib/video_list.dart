import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoList extends StatefulWidget {
  @override
  _VideoListState createState() => _VideoListState();
}

class _VideoListState extends State<VideoList> {
  var controllers = <YoutubePlayerController>[];
  var videoIds = <String>[
    "7QUtEmBT_-w",
    "QbSzrWYqNRg",
    "nONOGLMzXjc",
    "sf3oOx90j9Y",
    "2BEATsAvouU",
  ];

  @override
  void initState() {
    super.initState();
    videoIds.forEach(
      (videoId) => controllers.add(
            YoutubePlayerController(initialSource: videoId),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video List"),
      ),
      body: ListView.separated(
        itemBuilder: (context, index) => _player(context, controllers[index]),
        separatorBuilder: (_, i) => SizedBox(
              height: 10.0,
            ),
        itemCount: controllers.length,
      ),
    );
  }

  Widget _player(BuildContext context, YoutubePlayerController controller) =>
      YoutubePlayer(
        context: context,
        autoPlay: false,
        showVideoProgressIndicator: true,
        controller: controller,
      );
}
