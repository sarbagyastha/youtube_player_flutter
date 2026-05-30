import 'package:flutter/material.dart';

import 'pages/player_page.dart';

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Color _seedColor = const Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Player Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      ),
      home: PlayerPage(
        seedColor: _seedColor,
        onColorChanged: (color) => setState(() => _seedColor = color),
      ),
    );
  }
}
