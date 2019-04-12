import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  testWidgets(
    'show player',
    (WidgetTester tester) async {
      BuildContext context;
      await tester.pumpWidget(
        YoutubePlayer(
          key: ValueKey("sarbagya"),
          context: context,
          videoId: "BBAyRBTfsOU",
          autoPlay: true,
          width: 300,
          aspectRatio: 16 / 9,
          controlsTimeOut: Duration(seconds: 2),
          hideControls: false,
          onPlayerInitialized: (controller) {},
          progressColors: ProgressColors(
            handleColor: Colors.red,
            backgroundColor: Colors.red,
            bufferedColor: Colors.red,
            playedColor: Colors.red,
          ),
          showVideoProgressIndicator: true,
          videoProgressIndicatorColor: Colors.red,
        ),
      );
      expect(find.byKey(ValueKey("sarbagya")), findsOneWidget);
    },
  );
}
