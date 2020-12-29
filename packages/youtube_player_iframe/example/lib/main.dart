// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'widgets/meta_data_section.dart';
import 'widgets/play_pause_button_bar.dart';
import 'widgets/player_state_section.dart';
import 'widgets/source_input_section.dart';
import 'widgets/volume_slider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(YoutubeApp());
}

///
class YoutubeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Youtube Player IFrame Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.deepPurpleAccent),
      ),
      debugShowCheckedModeBanner: false,
      home: YoutubeAppDemo(),
    );
  }
}

///
class YoutubeAppDemo extends StatefulWidget {
  @override
  _YoutubeAppDemoState createState() => _YoutubeAppDemoState();
}

class _YoutubeAppDemoState extends State<YoutubeAppDemo> {
  YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: 'F1B9Fk_SgI0',
      params: YoutubePlayerParams(
        playlist: [
          "MnrJzXM7a6o",
          "FTQbiNvZqaY",
          "iYKXdt0LRs8",
        ],
        //startAt: Duration(minutes: 1, seconds: 5),
        showControls: true,
        showFullscreenButton: true,
        desktopMode: false, // false for platform design
        autoPlay: false,
        enableCaption: true,
        showVideoAnnotations: false,
        enableJavaScript: true,
        privacyEnhanced: true,
        playsInline: false, // iOS only - Auto fullscreen or not
      ),
    )..listen((value) {
        if (value.isReady && !value.hasPlayed) {
          _controller
            ..hidePauseOverlay()
            // Uncomment below to start autoplay on iOS
            //..play()
            ..hideTopMenu();
        }
      });
    //Uncomment below for auto rotation on fullscreen
    // _controller.onEnterFullscreen = () {
    //   SystemChrome.setPreferredOrientations([
    //     DeviceOrientation.landscapeLeft,
    //     DeviceOrientation.landscapeRight,
    //   ]);
    //   log('Entered Fullscreen');
    // };
    // _controller.onExitFullscreen = () {
    //   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    //   Future.delayed(const Duration(seconds: 1), () {
    //     _controller.play();
    //   });
    //   Future.delayed(const Duration(seconds: 5), () {
    //     SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    //   });
    //   log('Exited Fullscreen');
    // };
  }

  @override
  Widget build(BuildContext context) {
    const player = YoutubePlayerIFrame();
    return YoutubePlayerControllerProvider(
      // Passing controller to widgets below.
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Youtube Player Demo'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (kIsWeb && constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: player),
                  const SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                      child: Controls(),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              children: [
                player,
                const Controls(),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

///
class Controls extends StatelessWidget {
  ///
  const Controls();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _space,
          MetaDataSection(),
          _space,
          SourceInputSection(),
          _space,
          PlayPauseButtonBar(),
          _space,
          VolumeSlider(),
          _space,
          PlayerStateSection(),
        ],
      ),
    );
  }

  Widget get _space => const SizedBox(height: 10);
}
