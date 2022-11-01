import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

///
class FullScreenPlayerPage extends StatefulWidget {
  ///
  const FullScreenPlayerPage({
    super.key,
    required this.videoId,
    required this.startSeconds,
  });

  ///
  final String videoId;

  ///
  final double startSeconds;

  @override
  State<FullScreenPlayerPage> createState() => _FullScreenPlayerPageState();
}

class _FullScreenPlayerPageState extends State<FullScreenPlayerPage> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      startSeconds: widget.startSeconds,
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    )..onFullscreenChange = (_) async {
        Navigator.pop(context, await _controller.currentTime);
      };

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, await _controller.currentTime);
        return false;
      },
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: MediaQuery.of(context).size.aspectRatio,
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controller.close();

    super.dispose();
  }
}
