// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'pages/player_page.dart';

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Color _seedColor = const Color(0xFF2196F3);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Player Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: _seedColor,
        brightness: Brightness.dark,
      ),
      home: PlayerPage(
        seedColor: _seedColor,
        onColorChanged: (color) => setState(() => _seedColor = color),
      ),
    );
  }
}
