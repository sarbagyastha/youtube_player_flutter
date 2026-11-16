import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:youtube_player/youtube_player.dart';

/// Pumps frames until [condition] holds or [timeout] elapses.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
  String reason = '',
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting: $reason');
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads, plays, seeks and reports state', (tester) async {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: 'M7lc1UVf-VE', // YouTube's own IFrame API demo video.
      params: const YoutubePlayerParams(mute: true),
    );
    final states = <YoutubeVideoState>[];
    final sub = controller.videoStateStream.listen(states.add);

    await tester.pumpWidget(
      Directionality(
        textDirection: .ltr,
        child: Center(
          child: SizedBox(
            width: 640,
            child: YoutubePlayer(controller: controller),
          ),
        ),
      ),
    );

    await pumpUntil(tester, () => controller.value.isReady, reason: 'ready');
    expect(
      controller.value.error,
      YoutubeError.none,
      reason: 'no client identity error (153) expected',
    );

    controller.playVideo();
    await pumpUntil(
      tester,
      () => controller.value.playerState == .playing,
      reason: 'playing (state: ${controller.value.playerState})',
    );
    expect(controller.metadata.videoId, 'M7lc1UVf-VE');
    expect(controller.metadata.duration, greaterThan(Duration.zero));

    await pumpUntil(tester, () => states.isNotEmpty, reason: 'ticks');

    controller.seekTo(seconds: 30, allowSeekAhead: true);
    await pumpUntil(
      tester,
      () => states.isNotEmpty && states.last.position.inSeconds >= 30,
      reason: 'seek',
    );

    controller.setPlaybackRate(1.5);
    await pumpUntil(
      tester,
      () => controller.value.playbackRate == 1.5,
      reason: 'rate',
    );

    expect(await controller.availablePlaybackRates, contains(1.5));
    expect(await controller.videoUrl, contains('M7lc1UVf-VE'));

    controller.pauseVideo();
    await pumpUntil(
      tester,
      () => controller.value.playerState == .paused,
      reason: 'paused',
    );

    // Volume changes while paused (no running clock) must still sync.
    controller.unMute();
    await pumpUntil(
      tester,
      () => !controller.value.isMuted,
      timeout: const Duration(seconds: 5),
      reason: 'unmuted while paused',
    );
    controller.mute();
    await pumpUntil(
      tester,
      () => controller.value.isMuted,
      timeout: const Duration(seconds: 5),
      reason: 'muted while paused',
    );

    await sub.cancel();
    controller.close();
    await tester.pumpWidget(const SizedBox());
  });
}
