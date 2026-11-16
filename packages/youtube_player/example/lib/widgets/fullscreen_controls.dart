import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

/// Enters, toggles and leaves the platform's fullscreen presentation.
class const FullscreenControls({super.key}) extends StatefulWidget {
  @override
  State<FullscreenControls> createState() => _FullscreenControlsState();
}

class _FullscreenControlsState extends State<FullscreenControls> {
  YoutubePlayerController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.ytController;
    if (controller == _controller) return;
    _controller = controller
      ..setFullScreenListener((fullScreen) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                fullScreen ? 'Entered fullscreen' : 'Left fullscreen',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
      });
  }

  Future<void> _enter({Duration? exitAfter}) async {
    final controller = context.ytController;
    final accepted = await controller.enterFullScreen();
    if (!mounted) return;
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Refused here. Use the fullscreen button in the player.',
          ),
        ),
      );
    } else if (exitAfter != null) {
      await Future<void>.delayed(exitAfter);
      controller.exitFullScreen();
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      FilledButton.tonalIcon(
        onPressed: _enter,
        icon: const Icon(Icons.fullscreen),
        label: const Text('Enter'),
      ),
      OutlinedButton.icon(
        onPressed: context.ytController.toggleFullScreen,
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Toggle'),
      ),
      OutlinedButton.icon(
        onPressed: () => _enter(exitAfter: const Duration(seconds: 5)),
        icon: const Icon(Icons.timer_outlined),
        label: const Text('Enter for 5 s'),
      ),
    ],
  );
}
