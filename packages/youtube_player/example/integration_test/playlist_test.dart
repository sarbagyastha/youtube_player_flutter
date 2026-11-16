import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:youtube_player/youtube_player.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  String reason = '',
}) async {
  final end = DateTime.now().add(const Duration(seconds: 30));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting: $reason');
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('video-id playlists load and navigate', (tester) async {
    const ids = ['M7lc1UVf-VE', 'dQw4w9WgXcQ', 'jNQXAC9IVRw'];
    final controller = YoutubePlayerController(
      params: const YoutubePlayerParams(mute: true),
    );
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

    await controller.loadPlaylist(list: ids);
    await pumpUntil(
      tester,
      () => controller.metadata.videoId == ids[0],
      reason: 'first video',
    );
    expect(await controller.playlist, ids);
    expect(await controller.playlistIndex, 0);

    await controller.nextVideo();
    await pumpUntil(
      tester,
      () => controller.metadata.videoId == ids[1],
      reason: 'next video',
    );
    expect(await controller.playlistIndex, 1);

    await controller.previousVideo();
    await pumpUntil(
      tester,
      () => controller.metadata.videoId == ids[0],
      reason: 'previous video',
    );

    await controller.playVideoAt(2);
    await pumpUntil(
      tester,
      () => controller.metadata.videoId == ids[2],
      reason: 'playVideoAt',
    );

    await controller.close();
    await tester.pumpWidget(const SizedBox());
  });
}
