import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:youtube_player/youtube_player.dart';
import 'package:youtube_player_example/main.dart';

/// Pumps frames until [condition] holds or [timeout] elapses.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
  String Function()? reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out: ${reason?.call()}');
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('example controls follow the player', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final controller = YoutubePlayerControllerProvider.of(
      tester.element(find.byType(YoutubePlayer)),
    );

    bool shows(IconData icon) => find.byIcon(icon).evaluate().isNotEmpty;
    String state() =>
        'value: ${controller.value}, '
        'pauseIcon: ${shows(Icons.pause)}, playIcon: ${shows(Icons.play_arrow)}, '
        'mutedIcon: ${shows(Icons.volume_off)}, unmutedIcon: ${shows(Icons.volume_up)}';

    final positions = <Duration>[];
    controller.videoStateStream.listen((s) => positions.add(s.position));

    /// Whether playback really advances, independent of reported state.
    Future<bool> advancing() async {
      final before = positions.isEmpty ? Duration.zero : positions.last;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final after = positions.isEmpty ? Duration.zero : positions.last;
      return after - before > const Duration(milliseconds: 800);
    }

    Future<void> expectButtonMatchesPlayer(String step) async {
      // Let the seek settle, then compare reported state, button and truth.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final active = controller.value.playerState.isActive;
      final moving = await advancing();
      expect(
        (active, shows(Icons.pause), moving),
        (moving, moving, moving),
        reason: '$step: reported active=$active, ${state()}',
      );
    }

    // Autoplays muted once visible.
    await pumpUntil(
      tester,
      () => controller.value.playerState == .playing,
      reason: state,
    );
    // Small windows (desktop tests) don't build the controls row yet.
    await tester.scrollUntilVisible(
      find.byIcon(Icons.speed),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpUntil(tester, () => shows(Icons.pause), reason: state);
    await pumpUntil(tester, () => shows(Icons.volume_off), reason: state);

    // Our mute button.
    await tester.tap(find.byIcon(Icons.volume_off));
    await pumpUntil(
      tester,
      () => !controller.value.isMuted && shows(Icons.volume_up),
      timeout: const Duration(seconds: 5),
      reason: state,
    );
    await tester.tap(find.byIcon(Icons.volume_up));
    await pumpUntil(
      tester,
      () => controller.value.isMuted && shows(Icons.volume_off),
      timeout: const Duration(seconds: 5),
      reason: state,
    );

    // Our seek bar while playing.
    final slider = find.byType(Slider);
    await tester.timedDrag(
      slider,
      Offset(tester.getSize(slider).width * 0.3, 0),
      const Duration(milliseconds: 600),
    );
    await expectButtonMatchesPlayer('seek while playing');

    // Pause from our button.
    await tester.tap(find.byIcon(Icons.pause));
    await pumpUntil(
      tester,
      () => controller.value.playerState == .paused && shows(Icons.play_arrow),
      timeout: const Duration(seconds: 5),
      reason: state,
    );

    // Our seek bar while paused.
    await tester.timedDrag(
      slider,
      Offset(-tester.getSize(slider).width * 0.2, 0),
      const Duration(milliseconds: 600),
    );
    await expectButtonMatchesPlayer('seek while paused');
  });
}
