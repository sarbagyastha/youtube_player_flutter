import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_player_flutter_example/video_list.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.blueAccent,
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Youtube Player Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          color: Colors.blueAccent,
          textTheme: TextTheme(
            title: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontSize: 20.0,
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.blueAccent,
        ),
      ),
      home: MyHomePage(title: 'Youtube Player Flutter'),
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  YoutubePlayerController _controller = YoutubePlayerController();
  var _idController = TextEditingController();
  var _seekToController = TextEditingController();
  double _volume = 100;
  bool _muted = false;
  String _playerStatus = "";

  void listener() {
    if (_controller.value.playerState == PlayerState.ended) {
      _showSnackBar('Video Ended!');
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          key: _scaffoldKey,
          appBar: orientation == Orientation.landscape
              ? null
              : AppBar(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Image.asset(
                      'assets/ypf.png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  title: Text(
                    widget.title,
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.video_library),
                      onPressed: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => VideoList(),
                        ),
                      ),
                    ),
                  ],
                ),
          body: SingleChildScrollView(
            physics: orientation == Orientation.landscape
                ? NeverScrollableScrollPhysics()
                : AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                YoutubePlayer(
                  context: context,
                  initialVideoId: 'tcodrIK2P_I',
                  flags: YoutubePlayerFlags(
                    mute: false,
                    autoPlay: true,
                    forceHideAnnotation: true,
                    showVideoProgressIndicator: true,
                    disableDragSeek: false,
                    loop: true,
                    start: Duration(seconds: 95),
                  ),
                  progressIndicatorColor: Colors.blueAccent,
                  topActions: <Widget>[
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      onPressed: () {
                        _controller.exitFullScreenMode();
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Youtube Player Title Demo',
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
                        _showSnackBar('Settings Tapped!');
                      },
                    ),
                  ],
                  onPlayerInitialized: (controller) =>
                      _controller = controller..addListener(listener),
                ),
                if (orientation == Orientation.portrait) ...[
                  _space,
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextField(
                          controller: _idController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Enter youtube \<video id\> or \<link\>",
                          ),
                        ),
                        _space,
                        Row(
                          children: [
                            _loadCueButton('LOAD'),
                            SizedBox(width: 10.0),
                            _loadCueButton('CUE'),
                          ],
                        ),
                        _space,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              onPressed: () {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                                setState(() {});
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                  _muted ? Icons.volume_off : Icons.volume_up),
                              onPressed: () {
                                _muted
                                    ? _controller.unMute()
                                    : _controller.mute();
                                setState(() {
                                  _muted = !_muted;
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.fullscreen),
                              onPressed: () =>
                                  _controller.enterFullScreenMode(),
                            ),
                          ],
                        ),
                        _space,
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
                                onPressed: () {
                                  _controller.seekTo(
                                    Duration(
                                      seconds:
                                          int.parse(_seekToController.text),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        _space,
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
                        Chip(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.all(8.0),
                          avatar: Icon(
                            Icons.settings_input_antenna,
                            color: Colors.white,
                            size: 15.0,
                          ),
                          label: Text(
                            _playerStatus,
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget get _space => SizedBox(height: 10);

  Widget _loadCueButton(String action) {
    return Expanded(
      child: MaterialButton(
        color: Colors.blueAccent,
        onPressed: () {
          if (_idController.text.isNotEmpty) {
            String id = YoutubePlayer.convertUrlToId(
              _idController.text,
            );
            if (action == 'LOAD') _controller.load(id);
            if (action == 'CUE') _controller.cue(id);
            FocusScope.of(context).requestFocus(FocusNode());
          } else {
            _showSnackBar('Source can\'t be empty!');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Text(
            action,
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
      ),
    );
  }
}
