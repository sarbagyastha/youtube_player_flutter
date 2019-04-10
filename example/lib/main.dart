import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_player_flutter_example/video_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Youtube Player Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'Youtube Player Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  YoutubePlayerController controller;
  var _idController = TextEditingController();
  var _seekToController = TextEditingController();
  double _volume = 100;
  bool _muted = false;
  String _playerStatus = "";

  @override
  void initState() {
    super.initState();
    controller = YoutubePlayerController(
      initialSource: 'iLnmTe5Q2Qw',
    )..addListener(listener);
  }

  void listener() {
    if (controller.value.playerState == PlayerState.ENDED) {
      _showThankYouDialog();
    }
    setState(() {
      _playerStatus = controller.value.playerState.toString();
    });
  }

  @override
  void deactivate() {
    controller.pause();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.video_library,
              color: Colors.white,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VideoList()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            YoutubePlayer(
              context: context,
              controller: controller,
              autoPlay: true,
              showVideoProgressIndicator: true,
              videoProgressIndicatorColor: Colors.amber,
              progressColors: ProgressColors(
                playedColor: Colors.amber,
                handleColor: Colors.amberAccent,
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter youtube \<video id\> or \<link\>"),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  InkWell(
                    onTap: () {
                      controller.changeSource(_idController.text);
                      setState(() {});
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 16.0,
                      ),
                      color: Colors.amber,
                      child: Text(
                        "PLAY",
                        style: TextStyle(fontSize: 18.0, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          controller.value.isPlaying
                              ? Icons.play_arrow
                              : Icons.pause,
                        ),
                        onPressed: () {
                          controller.value.isPlaying
                              ? controller.pause()
                              : controller.play();
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                        onPressed: () {
                          _muted ? controller.unMute() : controller.mute();
                          setState(() {
                            _muted = !_muted;
                          });
                        },
                      ),
                      IconButton(
                          icon: Icon(Icons.fullscreen),
                          onPressed: () => controller.enterFullScreen()),
                    ],
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  TextField(
                    controller: _seekToController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Seek to seconds",
                      suffixIcon: Padding(
                        padding: EdgeInsets.all(5.0),
                        child: OutlineButton(
                          child: Text("Seek"),
                          onPressed: () => controller.seekTo(
                                Duration(
                                  seconds: int.parse(_seekToController.text),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        "Volume",
                        style: TextStyle(fontWeight: FontWeight.w300),
                      ),
                      Expanded(
                        child: Slider(
                          inactiveColor: Colors.transparent,
                          value: _volume,
                          min: 0.0,
                          max: 100.0,
                          divisions: 10,
                          label: '${(_volume).round()}',
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                            });
                            controller.setVolume(_volume.round());
                          },
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Status: $_playerStatus",
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Video Ended"),
          content: Text("Thank you for trying the plugin!"),
        );
      },
    );
  }
}
