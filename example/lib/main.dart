import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Color(0xFFFF0000),
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Youtube Player Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
        appBarTheme: AppBarTheme(color: Color(0xFFFF0000)),
        iconTheme: IconThemeData(
          color: Colors.red,
        ),
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
  YoutubePlayerController _controller = YoutubePlayerController();
  var _idController = TextEditingController();
  var _seekToController = TextEditingController();
  double _volume = 100;
  bool _muted = false;
  String _playerStatus = "";
  String _videoId = "50kklGefAcs";

  void listener() {
    if (_controller.value.playerState == PlayerState.ended) {
      _showThankYouDialog();
    }
    if (mounted) {
      setState(() {
        _playerStatus = _controller.value.playerState.toString();
      });
    }
  }

  @override
  void deactivate() {
    // This pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _controller.value.isFullScreen
          ? null
          : AppBar(
              title: Text(
                widget.title,
                style: TextStyle(color: Colors.white),
              ),
            ),
      body: Builder(builder: (context) {
        return SingleChildScrollView(
          child: Column(
            children: [
              YoutubePlayer(
                context: context,
                videoId: _videoId,
                flags: YoutubePlayerFlags(
                  mute: false,
                  autoPlay: true,
                  forceHideAnnotation: true,
                  showVideoProgressIndicator: true,
                  disableDragSeek: false,
                  loop: true,
                ),
                progressIndicatorColor: Color(0xFFFF0000),
                topActions: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20.0,
                    ),
                    onPressed: () {
                      _controller.exitFullScreen();
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Bhanchu Aaja || Ma Yesto Geet Gaunchu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 25.0,
                    ),
                    onPressed: () {
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Settings Tapped!'),
                        ),
                      );
                    },
                  ),
                ],
                onPlayerInitialized: (controller) =>
                    _controller = controller..addListener(listener),
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
                        setState(() {
                          _videoId = _idController.text;
                          // If text is link then converting to corresponding id.
                          if (_videoId.contains("http"))
                            _videoId = YoutubePlayer.convertUrlToId(_videoId);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 16.0,
                        ),
                        color: Color(0xFFFF0000),
                        child: Text(
                          "LOAD",
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
                            _controller.value.isPlaying
                                ? Icons.play_arrow
                                : Icons.pause,
                          ),
                          onPressed: () {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                            setState(() {});
                          },
                        ),
                        IconButton(
                          icon:
                              Icon(_muted ? Icons.volume_off : Icons.volume_up),
                          onPressed: () {
                            _muted ? _controller.unMute() : _controller.mute();
                            setState(() {
                              _muted = !_muted;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.fullscreen),
                          onPressed: () => _controller.enterFullScreen(),
                        ),
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
                            onPressed: () => _controller.seekTo(
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
                              _controller.setVolume(_volume.round());
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
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
