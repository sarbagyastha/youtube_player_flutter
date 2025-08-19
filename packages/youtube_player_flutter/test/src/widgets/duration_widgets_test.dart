import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../youtube_player_flutter_test.dart';

main() {
  group('CurrentPosition', () {
    testWidgets(
      'includes text with Colors.transparent color and "66:66" when duration is < 1hour',
      (widgetTester) async {
        final controller = createController();
        controller.value =
            YoutubePlayerValue(position: Duration(hours: 0, minutes: 1));

        await widgetTester.pumpWidget(
          MaterialApp(
            home: CurrentPosition(
              controller: controller,
            ),
          ),
        );

        await widgetTester.pumpAndSettle();
        final hiddenCurrentPositionText = widgetTester.widget<Text>(
            find.byKey(const Key('hidden-current-position-text')));
        expect(hiddenCurrentPositionText.data, '66:66');
        expect(hiddenCurrentPositionText.style?.color, Colors.transparent);
      },
    );

    testWidgets(
      'includes text with Colors.transparent color and "66:66:66" when duration is == 1hour',
      (widgetTester) async {
        final controller = createController();
        controller.value =
            YoutubePlayerValue(position: Duration(hours: 1, minutes: 0));

        await widgetTester.pumpWidget(
          MaterialApp(
            home: CurrentPosition(
              controller: controller,
            ),
          ),
        );

        await widgetTester.pumpAndSettle();
        final hiddenCurrentPositionText = widgetTester.widget<Text>(
            find.byKey(const Key('hidden-current-position-text')));
        expect(hiddenCurrentPositionText.data, '66:66:66');
        expect(hiddenCurrentPositionText.style?.color, Colors.transparent);
      },
    );

    testWidgets(
      'includes text with Colors.transparent color and "66:66:66" when duration is > 1hour',
      (widgetTester) async {
        final controller = createController();
        controller.value =
            YoutubePlayerValue(position: Duration(hours: 1, minutes: 0));

        await widgetTester.pumpWidget(
          MaterialApp(
            home: CurrentPosition(
              controller: controller,
            ),
          ),
        );

        await widgetTester.pumpAndSettle();
        final hiddenCurrentPositionText = widgetTester.widget<Text>(
            find.byKey(const Key('hidden-current-position-text')));
        expect(hiddenCurrentPositionText.data, '66:66:66');
        expect(hiddenCurrentPositionText.style?.color, Colors.transparent);
      },
    );
  });

  group('RemainingDuration', () {
    testWidgets(
      'includes text with Colors.transparent color and "- 66:66" when duration is < 1hour',
      (widgetTester) async {
        final controller = createController();
        controller.value =
            YoutubePlayerValue(position: Duration(hours: 0, minutes: 1));

        await widgetTester.pumpWidget(
          MaterialApp(
            home: RemainingDuration(
              controller: controller,
            ),
          ),
        );

        await widgetTester.pumpAndSettle();
        final hiddenCurrentPositionText = widgetTester.widget<Text>(
            find.byKey(const Key('hidden-remaining-duration-text')));
        expect(hiddenCurrentPositionText.data, '- 66:66');
        expect(hiddenCurrentPositionText.style?.color, Colors.transparent);
      },
    );

    testWidgets(
      'includes text with Colors.transparent color and "- 66:66:66" when duration is == 1hour',
      (widgetTester) async {
        final controller = createController();
        controller.value =
            YoutubePlayerValue(position: Duration(hours: 1, minutes: 0));

        await widgetTester.pumpWidget(
          MaterialApp(
            home: RemainingDuration(
              controller: controller,
            ),
          ),
        );

        await widgetTester.pumpAndSettle();
        final hiddenCurrentPositionText = widgetTester.widget<Text>(
            find.byKey(const Key('hidden-remaining-duration-text')));
        expect(hiddenCurrentPositionText.data, '- 66:66:66');
        expect(hiddenCurrentPositionText.style?.color, Colors.transparent);
      },
    );

    testWidgets(
      'includes text with Colors.transparent color and "- 66:66:66" when duration is > 1hour',
      (widgetTester) async {
        final controller = createController();
        controller.value =
            YoutubePlayerValue(position: Duration(hours: 1, minutes: 0));

        await widgetTester.pumpWidget(
          MaterialApp(
            home: RemainingDuration(
              controller: controller,
            ),
          ),
        );

        await widgetTester.pumpAndSettle();
        final hiddenCurrentPositionText = widgetTester.widget<Text>(
            find.byKey(const Key('hidden-remaining-duration-text')));
        expect(hiddenCurrentPositionText.data, '- 66:66:66');
        expect(hiddenCurrentPositionText.style?.color, Colors.transparent);
      },
    );
  });
}
