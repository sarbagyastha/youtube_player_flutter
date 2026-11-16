import 'package:material_ui/material_ui.dart';

import 'pages/home_page.dart';

/// The example app: a gallery of `youtube_player` demos.
class const ExampleApp({super.key, final Widget home = const HomePage()})
    extends StatelessWidget {
  /// YouTube red.
  static const seed = Color(0xFFFF0000);

  /// The app theme for [brightness].
  static ThemeData theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: .fidelity,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: .zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: .circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      chipTheme: const ChipThemeData(showCheckmark: false),
      listTileTheme: const ListTileThemeData(contentPadding: .zero),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .5),
        border: OutlineInputBorder(
          borderRadius: .circular(14),
          borderSide: .none,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: .floating),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'youtube_player',
    debugShowCheckedModeBanner: false,
    theme: theme(.light),
    darkTheme: theme(.dark),
    home: home,
  );
}
