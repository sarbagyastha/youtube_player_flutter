import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

/// Builds the player of a [DemoScaffold].
typedef PlayerBuilder = Widget Function(
  BuildContext context,
  YoutubePlayerController controller,
);

/// The layout shared by the demo pages.
///
/// Creates the controller with [create], provides it to [children] (read it
/// with `context.ytController`) and closes it on dispose. On narrow screens
/// in portrait the player stays on top while [children] scroll below it;
/// on wide or landscape screens they sit side by side.
class const DemoScaffold({
  super.key,
  required final String title,
  required final YoutubePlayerController Function() create,
  required final List<Widget> children,

  /// Builds the player; defaults to a plain `YoutubePlayer`.
  final PlayerBuilder? playerBuilder,

  /// Change this to close the controller and create a new one.
  final Object? controllerKey,
  final List<Widget> actions = const [],
}) extends StatefulWidget {
  @override
  State<DemoScaffold> createState() => _DemoScaffoldState();
}

class _DemoScaffoldState extends State<DemoScaffold> {
  late YoutubePlayerController _controller = widget.create();

  @override
  void didUpdateWidget(DemoScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controllerKey != widget.controllerKey) {
      _controller.close();
      _controller = widget.create();
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YoutubePlayerControllerProvider(
    controller: _controller,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: widget.actions),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final player = KeyedSubtree(
            key: ObjectKey(_controller),
            child:
                widget.playerBuilder?.call(context, _controller) ??
                YoutubePlayer(controller: _controller),
          );
          // Few sections, so build them all: no lazy list.
          final sections = SingleChildScrollView(
            padding: const .fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: 12,
              children: widget.children,
            ),
          );
          // Pinning a 16:9 player on top only works in portrait; landscape
          // windows (e.g. a phone on its side) go side by side.
          final sideBySide =
              constraints.maxWidth >= 900 ||
              (constraints.maxWidth >= 600 &&
                  constraints.maxWidth > constraints.maxHeight);
          if (!sideBySide) {
            return Column(
              children: [
                player,
                Expanded(child: sections),
              ],
            );
          }
          return Row(
            crossAxisAlignment: .start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const .fromLTRB(24, 16, 8, 24),
                  child: _Framed(child: player),
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth * .5).clamp(0, 440),
                child: sections,
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// A shadow around the player. Deliberately no clip: clipping a platform
/// view costs per-frame work on iOS.
class const _Framed({required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: .25),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}
