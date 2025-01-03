import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../youtube_player_flutter_test.dart';

main() {
  const expectedSize = 123.456;

  testWidgets(
      'CircularProgressIndicator uses correct size based on passed size',
      (WidgetTester tester) async {
    final controller = createController();
    const expectedProgressIndicatorSize = expectedSize * 7 / 6;

    await tester.pumpWidget(PlayPauseButton(
      controller: controller,
      size: expectedSize,
    ));
    final defaultBufferIndicatorFinder =
        find.byKey(const Key('default-buffer-indicator'));
    await tester.waitFor(defaultBufferIndicatorFinder);
    final defaultBufferIndicatorSizedBox =
        tester.widget<SizedBox>(defaultBufferIndicatorFinder);
    expect(
        defaultBufferIndicatorSizedBox.height, expectedProgressIndicatorSize);
    expect(defaultBufferIndicatorSizedBox.width, expectedProgressIndicatorSize);
  });

  testWidgets('uses passed size', (WidgetTester tester) async {
    final controller = createController();
    controller.value = YoutubePlayerValue(
        playerState: PlayerState.playing, isControlsVisible: true);

    await tester.pumpWidget(
      MaterialApp(
        home: PlayPauseButton(
          controller: controller,
          size: expectedSize,
        ),
      ),
    );

    await tester.pumpAndSettle();
    final animatedIcon = tester.widget<AnimatedIcon>(find.byType(AnimatedIcon));
    expect(animatedIcon.size, expectedSize);
  });

  testWidgets('has a size of 60 when no size is passed',
      (WidgetTester tester) async {
    final controller = createController();
    controller.value = YoutubePlayerValue(
        playerState: PlayerState.playing, isControlsVisible: true);

    await tester.pumpWidget(
      MaterialApp(
        home: PlayPauseButton(
          controller: controller,
        ),
      ),
    );

    await tester.pumpAndSettle();
    final animatedIcon = tester.widget<AnimatedIcon>(find.byType(AnimatedIcon));
    expect(animatedIcon.size, 60.0);
  });
}
