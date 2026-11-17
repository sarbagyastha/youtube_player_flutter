import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

/// Counts how often the platform view is created; reparenting must not
/// create a new one.
class const _ViewProbe() extends StatefulWidget {
  static var created = 0;

  @override
  State<_ViewProbe> createState() => _ViewProbeState();
}

class _ViewProbeState extends State<_ViewProbe> {
  @override
  void initState() {
    super.initState();
    _ViewProbe.created++;
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: ValueKey('view'));
}

final class _FakeHost implements YoutubePlayerHost {
  final _events = StreamController<PlayerEvent>.broadcast(sync: true);

  @override
  Stream<PlayerEvent> get events => _events.stream;

  @override
  Stream<NavigationRequest> get navigations => const Stream.empty();

  @override
  bool get supportsElementControl => true;

  @override
  void setHiddenElements(Set<PlayerElement> elements) {}

  @override
  void resolveClick(int clickId, {required bool allow}) {}

  @override
  Stream<bool> get fullscreenChanges => const Stream.empty();

  @override
  void call(PlayerMethod method, [List<Object?> args = const []]) {}

  @override
  Future<Object?> query(
    PlayerMethod method, [
    List<Object?> args = const [],
  ]) async => null;

  @override
  void setBackgroundColor(Color color) {}

  @override
  void exitFullscreen() {}

  @override
  Widget buildView({
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = const {},
  }) => const _ViewProbe();

  @override
  void dispose() {}
}

final class _FakePlatform extends YoutubePlayerPlatform
    with MockPlatformInterfaceMixin {
  @override
  bool openExternal(Uri uri) => true;

  @override
  Future<YoutubePlayerHost> createHost(YoutubeHostParams params) async =>
      _FakeHost();
}

void main() {
  late YoutubePlayerController controller;
  late List<bool> changes;

  setUp(() {
    YoutubePlayerPlatform.instance = _FakePlatform();
    _ViewProbe.created = 0;
    changes = [];
  });

  // Created inside each test body, so its futures run in the test's fake
  // async zone.
  void createController() =>
      controller = YoutubePlayerController.fromVideoId(videoId: 'M7lc1UVf-VE');

  tearDown(() => controller.close());

  Future<void> pumpPlayer(WidgetTester tester, {bool show = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: show
              ? YoutubePlayer(
                  controller: controller,
                  autoFullScreen: false,
                  onFullScreenChanged: changes.add,
                )
              : const SizedBox(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  YoutubeFullScreenController fullScreenOf(WidgetTester tester) =>
      YoutubeFullScreen.of(
        tester.element(find.byType(FullscreenButton)),
        listen: false,
      );

  testWidgets('moves the view into fullscreen and back without recreating it', (
    tester,
  ) async {
    createController();
    await pumpPlayer(tester);
    expect(_ViewProbe.created, 1);
    final inlineSize = tester.getSize(find.byKey(const ValueKey('view')));

    await tester.tap(find.byIcon(Icons.fullscreen_rounded));
    await tester.pump();
    expect(fullScreenOf(tester).isFullScreen, isTrue);
    expect(find.byKey(const ValueKey('view')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('view'))),
      tester.view.physicalSize / tester.view.devicePixelRatio,
    );
    expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.fullscreen_exit_rounded));
    await tester.pump();
    expect(fullScreenOf(tester).isFullScreen, isFalse);
    expect(tester.getSize(find.byKey(const ValueKey('view'))), inlineSize);

    expect(_ViewProbe.created, 1);
    expect(changes, [true, false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back leaves fullscreen', (tester) async {
    createController();
    await pumpPlayer(tester);
    fullScreenOf(tester).enter();
    await tester.pump();
    expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(fullScreenOf(tester).isFullScreen, isFalse);
    expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
    expect(_ViewProbe.created, 1);
    expect(changes, [true, false]);
  });

  testWidgets('removing the player while fullscreen removes the route', (
    tester,
  ) async {
    createController();
    await pumpPlayer(tester);
    fullScreenOf(tester).enter();
    await tester.pump();

    await pumpPlayer(tester, show: false);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('view')), findsNothing);
    expect(find.byType(FullscreenButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical swipe toggles fullscreen outside scroll views', (
    tester,
  ) async {
    createController();
    await pumpPlayer(tester);
    final player = find.byKey(const ValueKey('view'));

    await tester.fling(player, const Offset(0, -200), 1000);
    await tester.pump();
    expect(fullScreenOf(tester).isFullScreen, isTrue);

    await tester.fling(player, const Offset(0, 200), 1000);
    await tester.pump();
    expect(fullScreenOf(tester).isFullScreen, isFalse);
  });

  testWidgets('vertical swipe scrolls instead when inside a scroll view', (
    tester,
  ) async {
    createController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              YoutubePlayer(controller: controller, autoFullScreen: false),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // Off the centre play button, on the bare controls layer.
    await tester.flingFrom(
      tester.getTopLeft(find.byKey(const ValueKey('view'))) +
          const Offset(40, 120),
      const Offset(0, -200),
      1000,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.fullscreen_exit_rounded), findsNothing);
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );
  });
}
