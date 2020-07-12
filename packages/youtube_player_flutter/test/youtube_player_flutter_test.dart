import 'dart:io';
import 'dart:ui' show window;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:youtube_player_flutter/src/player/youtube_player.dart';
import 'package:youtube_player_flutter/src/utils/youtube_player_controller.dart';
import 'package:youtube_player_flutter/src/utils/youtube_player_flags.dart';
import 'package:youtube_player_flutter/src/widgets/widgets.dart';

Widget buildPlayer({
  YoutubePlayerController controller,
  double width,
  List<Widget> bottomActions,
  List<Widget> topActions,
  bool showVideoProgressIndicator = true,
  double aspectRatio = 16 / 9,
  Widget bufferIndicator,
  Duration controlsTimeOut = const Duration(seconds: 3),
  Color liveUIColor = Colors.red,
  void Function() onReady,
  ProgressBarColors progressBarColors,
  Color progressIndicatorColor,
  Widget thumbnail,
  EdgeInsetsGeometry actionsPadding = const EdgeInsets.all(8.0),
}) {
  return TestApp(
    child: YoutubePlayer(
      controller: controller,
      width: width,
      bottomActions: bottomActions,
      actionsPadding: actionsPadding,
      showVideoProgressIndicator: showVideoProgressIndicator,
      aspectRatio: aspectRatio,
      bufferIndicator: bufferIndicator,
      controlsTimeOut: controlsTimeOut,
      liveUIColor: liveUIColor,
      onReady: onReady,
      progressColors: progressBarColors,
      progressIndicatorColor: progressIndicatorColor,
      thumbnail: thumbnail,
      topActions: topActions,
    ),
  );
}

YoutubePlayerController createController([YoutubePlayerFlags flags]) {
  return YoutubePlayerController(
    initialVideoId: 'p2lYr3vM_1w',
    flags: flags ?? const YoutubePlayerFlags(hideThumbnail: true),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create Youtube Player', (WidgetTester tester) async {
    provideMockedNetworkImages(() async {
      var _controller = createController();

      await tester.pumpWidget(buildPlayer(controller: _controller));
    });
  });
}

class TestApp extends StatelessWidget {
  final Widget child;
  final TextDirection textDirection;

  TestApp({
    this.textDirection = TextDirection.ltr,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: Directionality(
          textDirection: textDirection,
          child: child,
        ),
      ),
    );
  }
}

R provideMockedNetworkImages<R>(R body()) {
  return HttpOverrides.runZoned(
    body,
    createHttpClient: (_) => _createMockImageHttpClient(_, _transparentImage),
  );
}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {}

class MockHttpHeaders extends Mock implements HttpHeaders {}

// Returns a mock HTTP client that responds with an image to all requests.
MockHttpClient _createMockImageHttpClient(
    SecurityContext _, List<int> imageBytes) {
  final client = MockHttpClient();
  final request = MockHttpClientRequest();
  final response = MockHttpClientResponse();
  final headers = MockHttpHeaders();

  when(client.getUrl(any))
      .thenAnswer((_) => Future<HttpClientRequest>.value(request));
  when(request.headers).thenReturn(headers);
  when(request.close())
      .thenAnswer((_) => Future<HttpClientResponse>.value(response));
  when(response.contentLength).thenReturn(_transparentImage.length);
  when(response.statusCode).thenReturn(HttpStatus.ok);
  when(response.listen(any)).thenAnswer((Invocation invocation) {
    final void Function(List<int>) onData = invocation.positionalArguments[0];
    final void Function() onDone = invocation.namedArguments[#onDone];
    final void Function(Object, [StackTrace]) onError =
        invocation.namedArguments[#onError];
    final bool cancelOnError = invocation.namedArguments[#cancelOnError];

    return Stream<List<int>>.fromIterable(<List<int>>[imageBytes]).listen(
        onData,
        onDone: onDone,
        onError: onError,
        cancelOnError: cancelOnError);
  });
  return client;
}

const List<int> _transparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
];
