import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            height: 1000,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return const Column(
                    children: [
                      PlayerWidget(),
                      Divider(),
                      Expanded(child: _WebViewWidget()),
                    ],
                  );
                }

                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: PlayerWidget()),
                    VerticalDivider(),
                    Expanded(child: _WebViewWidget()),
                  ],
                );
              },
            ),
          ),
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

class _WebViewWidget extends StatefulWidget {
  const _WebViewWidget();

  @override
  State<_WebViewWidget> createState() => _WebViewWidgetState();
}

class _WebViewWidgetState extends State<_WebViewWidget> {
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()..loadRequest(Uri.https('flutter.dev'));
  }

  late final WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
