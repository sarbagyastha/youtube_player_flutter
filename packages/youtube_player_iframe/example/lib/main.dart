// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe_example/router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  usePathUrlStrategy();
  runApp(const YoutubeApp());
}

///
class YoutubeApp extends StatelessWidget {
  const YoutubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      dynamicSchemeVariant: DynamicSchemeVariant.expressive,
      brightness: Brightness.dark,
    );

    return MaterialApp.router(
      title: 'Youtube Player IFrame Demo',
      theme: ThemeData.from(colorScheme: colorScheme),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
