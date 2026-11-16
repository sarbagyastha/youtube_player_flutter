import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:youtube_player/youtube_player.dart';
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

final class FakeHost implements YoutubePlayerHost {
  final calls = <(PlayerMethod, List<Object?>)>[];
  final queryResults = <PlayerMethod, Object?>{};
  final eventController = StreamController<PlayerEvent>.broadcast(sync: true);
  final navController = StreamController<NavigationRequest>.broadcast(
    sync: true,
  );
  final hiddenUpdates = <Set<PlayerElement>>[];
  final resolved = <(int, bool)>[];
  var elementControl = true;
  final fullscreenController = StreamController<bool>.broadcast(sync: true);
  var disposed = false;
  var exitedFullscreen = false;

  void emit(PlayerEvent event) => eventController.add(event);

  @override
  Stream<PlayerEvent> get events => eventController.stream;

  @override
  Stream<NavigationRequest> get navigations => navController.stream;

  @override
  bool get supportsElementControl => elementControl;

  @override
  void setHiddenElements(Set<PlayerElement> elements) =>
      hiddenUpdates.add(elements);

  @override
  void resolveClick(int clickId, {required bool allow}) =>
      resolved.add((clickId, allow));

  @override
  Stream<bool> get fullscreenChanges => fullscreenController.stream;

  @override
  void call(PlayerMethod method, [List<Object?> args = const []]) =>
      calls.add((method, args));

  @override
  Future<Object?> query(
    PlayerMethod method, [
    List<Object?> args = const [],
  ]) async {
    calls.add((method, args));
    return queryResults[method];
  }

  @override
  void setBackgroundColor(Color color) {}

  @override
  void exitFullscreen() => exitedFullscreen = true;

  @override
  Widget buildView({
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = const {},
  }) => const SizedBox.expand();

  @override
  void dispose() => disposed = true;
}

final class FakePlatform extends YoutubePlayerPlatform
    with MockPlatformInterfaceMixin {
  final hosts = <FakeHost>[];
  final params = <YoutubeHostParams>[];
  var elementControl = true;
  final opened = <Uri>[];

  @override
  bool openExternal(Uri uri) {
    opened.add(uri);
    return true;
  }

  @override
  Future<YoutubePlayerHost> createHost(YoutubeHostParams params) async {
    this.params.add(params);
    return FakeHost()
      ..elementControl = elementControl
      ..let(hosts.add);
  }
}

extension<T> on T {
  void let(void Function(T) f) => f(this);
}

Future<void> pump() => Future<void>.delayed(Duration.zero);

void main() {
  late FakePlatform platform;

  setUp(() => YoutubePlayerPlatform.instance = platform = FakePlatform());

  test('queues calls until ready and keeps their order', () async {
    final controller = YoutubePlayerController();
    controller.playVideo();
    controller.seekTo(seconds: 10, allowSeekAhead: true);
    controller.setVolume(40);
    await pump();
    expect(platform.hosts, isEmpty, reason: 'calls do not create the host');
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single;
    expect(host.calls, isEmpty);

    host.emit(const ReadyEvent());
    await pump();
    expect(host.calls.map((c) => c.$1), [
      PlayerMethod.playVideo,
      PlayerMethod.seekTo,
      PlayerMethod.setVolume,
    ]);
    expect(host.calls[1].$2, [10.0, true]);
    expect(controller.value.isReady, isTrue);
  });

  test('fromVideoId passes the video and params to the platform', () async {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: 'dQw4w9WgXcQ',
      params: const YoutubePlayerParams(appId: 'np.com.example', mute: true),
    );
    await pump();
    expect(platform.params, isEmpty, reason: 'host is created lazily');
    unawaited(controller.host);
    await pump();
    final params = platform.params.single;
    expect(params.videoId, 'dQw4w9WgXcQ');
    expect(params.appId, 'np.com.example');
    expect(params.playerVars['mute'], 1);
    expect(params.host, 'https://www.youtube-nocookie.com');
  });

  test('caches state from events', () async {
    final controller = YoutubePlayerController();
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single;
    final states = <YoutubeVideoState>[];
    controller.videoStateStream.listen(states.add);

    host
      ..emit(const ReadyEvent())
      ..emit(
        const StateChangeEvent(
          .playing,
          videoData: VideoData(videoId: 'abc', title: 'T', author: 'A'),
          duration: 60,
        ),
      )
      ..emit(
        const TickEvent(
          currentTime: 12.5,
          loadedFraction: 0.4,
          duration: 60,
          volume: 70,
          muted: true,
        ),
      )
      ..emit(const PlaybackRateChangeEvent(1.5));
    await pump();

    expect(controller.currentTime, 12.5);
    expect(controller.volume, 70);
    expect(controller.isMuted, isTrue);
    expect(controller.playbackRate, 1.5);
    expect(controller.playerState, PlayerState.playing);
    expect(controller.metadata.title, 'T');
    expect(controller.metadata.duration, const Duration(minutes: 1));
    expect(states.single.position, const Duration(milliseconds: 12500));
    // Getters served from cache: no queries sent.
    expect(host.calls, isEmpty);

    host.emit(const StateChangeEvent(.cued));
    await pump();
    expect(controller.value.playbackRate, 1, reason: 'cue resets the rate');
  });

  test('mute, volume and rate follow what the player reports', () async {
    final controller = YoutubePlayerController(
      params: const YoutubePlayerParams(mute: true),
    );
    expect(controller.value.isMuted, isTrue, reason: 'seeded from params');
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single..emit(const ReadyEvent());
    final values = <YoutubePlayerValue>[];
    controller.listen(values.add);

    const tick = TickEvent(
      currentTime: 1,
      loadedFraction: 0.1,
      duration: 60,
      volume: 40,
      muted: false,
    );
    host
      ..emit(tick)
      ..emit(tick); // unchanged: no extra value
    await pump();
    expect(controller.value.isMuted, isFalse);
    expect(controller.value.volume, 40);
    expect(controller.isMuted, isFalse);
    expect(values.where((v) => v.volume == 40), hasLength(1));

    // A new playlist item keeps the reported rate instead of resetting to 1.
    host.emit(const StateChangeEvent(.unStarted, playbackRate: 1.5));
    await pump();
    expect(controller.value.playbackRate, 1.5);
    host.emit(const StateChangeEvent(.cued));
    await pump();
    expect(controller.value.playbackRate, 1, reason: 'fallback without r');
  });

  test('supportsVolume is false only on iOS', () {
    final controller = YoutubePlayerController();
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      expect(controller.supportsVolume, platform != .iOS, reason: '$platform');
    }
    controller.close();
  });

  test('errors and autoplay blocking reset when playing', () async {
    final controller = YoutubePlayerController();
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single;
    host
      ..emit(const ErrorEvent(.missingClientIdentity))
      ..emit(const AutoplayBlockedEvent());
    expect(controller.value.error, YoutubeError.missingClientIdentity);
    expect(controller.value.isAutoplayBlocked, isTrue);
    host.emit(const StateChangeEvent(.playing));
    expect(controller.value.hasError, isFalse);
    expect(controller.value.isAutoplayBlocked, isFalse);
  });

  test('related video links load in place by default', () async {
    final controller = YoutubePlayerController();
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single..emit(const ReadyEvent());
    expect(platform.params.single.interceptButtons, isFalse);

    host.navController.add(
      NavigationRequest(
        uri: Uri.parse(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=emb_rel_end',
        ),
        element: PlayerElement.relatedVideo,
      ),
    );
    await pump();
    expect(host.calls.single.$1, PlayerMethod.loadVideoById);
    expect(host.calls.single.$2, [
      {'videoId': 'dQw4w9WgXcQ'},
    ]);
    controller.close();
  });

  test('other links open externally through the platform', () async {
    final controller = YoutubePlayerController();
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single..emit(const ReadyEvent());
    final channel = Uri.parse('https://www.youtube.com/@channel');
    host.navController.add(
      NavigationRequest(uri: channel, element: PlayerElement.channel),
    );
    await pump();
    expect(platform.opened, [channel]);
    expect(host.calls, isEmpty);
    controller.close();
  });

  test('onNavigationRequest decides links and held buttons', () async {
    const custom = PlayerElement.custom('.my-thing');
    final requests = <NavigationRequest>[];
    final controller = YoutubePlayerController(
      params: const YoutubePlayerParams(customElements: {custom}),
      onNavigationRequest: (request) async {
        requests.add(request);
        return request.element == PlayerElement.shareButton
            ? .navigate
            : .prevent;
      },
    );
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single..emit(const ReadyEvent());
    expect(platform.params.single.interceptButtons, isTrue);
    expect(platform.params.single.customElements, {custom});

    host.navController
      ..add(
        NavigationRequest(
          uri: Uri.parse(
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=emb_rel_end',
          ),
          element: PlayerElement.relatedVideo,
        ),
      )
      ..add(
        const NavigationRequest(
          uri: null,
          element: PlayerElement.shareButton,
          clickId: 1,
        ),
      )
      ..add(
        NavigationRequest(
          uri: null,
          element: PlayerElement.byName('.my-thing'),
          clickId: 2,
        ),
      );
    await pump();
    await pump();
    // The related video was prevented, so nothing loads.
    expect(host.calls, isEmpty);
    expect(host.resolved, [(1, true), (2, false)]);
    expect(requests.map((r) => r.element.name), [
      'relatedVideo',
      'shareButton',
      '.my-thing',
    ]);
    // Custom elements come back as the app's own instance.
    expect(requests.last.element, same(custom));
    controller.close();
  });

  test('a throwing handler prevents the click', () async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);
    final controller = YoutubePlayerController(
      onNavigationRequest: (_) => throw StateError('boom'),
    );
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single;
    host.navController.add(
      const NavigationRequest(
        uri: null,
        element: PlayerElement.shareButton,
        clickId: 7,
      ),
    );
    await pump();
    expect(host.resolved, [(7, false)]);
    expect(errors.single.exception, isStateError);
    controller.close();
  });

  test('elementVisibility and setElementVisible hide elements', () async {
    const custom = PlayerElement.custom('.ytp-chrome-top');
    final controller = YoutubePlayerController(
      params: const YoutubePlayerParams(customElements: {custom}),
      elementVisibility: (e) =>
          e != PlayerElement.youtubeLogo && e.name != custom.name,
    );
    expect(controller.isElementVisible(PlayerElement.youtubeLogo), isFalse);
    // Before the player exists, changes only affect creation.
    controller.setElementVisible(PlayerElement.title, false);
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single;
    expect(platform.params.single.hiddenElements, {
      PlayerElement.youtubeLogo,
      custom,
      PlayerElement.title,
    });
    expect(host.hiddenUpdates, isEmpty);

    controller
      ..setElementVisible(PlayerElement.youtubeLogo, true)
      ..setElementVisible(PlayerElement.youtubeLogo, true)
      ..setElementVisible(PlayerElement.shareButton, false);
    expect(host.hiddenUpdates, [
      {custom, PlayerElement.title},
      {custom, PlayerElement.title, PlayerElement.shareButton},
    ]);
    expect(controller.isElementVisible(PlayerElement.youtubeLogo), isTrue);
    expect(controller.isElementVisible(PlayerElement.shareButton), isFalse);
    controller.close();
  });

  test('warns once when the platform cannot control elements', () async {
    final logs = <String?>[];
    final previous = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message);
    addTearDown(() => debugPrint = previous);
    platform.elementControl = false;
    final controller = YoutubePlayerController(
      elementVisibility: (e) => e != PlayerElement.youtubeLogo,
    );
    unawaited(controller.host);
    await pump();
    controller.setElementVisible(PlayerElement.title, false);
    expect(logs.where((l) => l!.contains('not supported')), hasLength(1));
    controller.close();
  });

  test('fullscreen is driven by the platform', () async {
    final controller = YoutubePlayerController();
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single;
    final changes = <bool>[];
    controller.setFullScreenListener(changes.add);
    host.fullscreenController.add(true);
    expect(controller.value.isFullScreen, isTrue);
    controller.toggleFullScreen();
    expect(host.exitedFullscreen, isTrue);
    host.fullscreenController.add(false);
    expect(changes, [true, false]);

    host
      ..queryResults[PlayerMethod.requestFullscreen] = true
      ..emit(const ReadyEvent());
    expect(await controller.enterFullScreen(), isTrue);
  });

  test(
    'video-id playlists use argument syntax, others object syntax',
    () async {
      final controller = YoutubePlayerController();
      unawaited(controller.host);
      await pump();
      final host = platform.hosts.single..emit(const ReadyEvent());
      controller.cuePlaylist(list: ['a', 'b'], index: 1);
      controller.loadPlaylist(list: ['PL123'], listType: .playlist);
      controller.cueVideoById(videoId: 'x', startSeconds: 5);
      expect(host.calls.map((c) => c.$2), [
        [
          ['a', 'b'],
          1,
          0,
        ],
        [
          {'listType': 'playlist', 'list': 'PL123'},
        ],
        [
          {'videoId': 'x', 'startSeconds': 5.0},
        ],
      ]);
    },
  );

  test('close disposes the host and silences later calls', () async {
    final controller = YoutubePlayerController();
    controller.playVideo();
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single;
    controller
      ..close()
      ..pauseVideo();
    expect(host.disposed, isTrue);
    expect(host.calls, isEmpty);
  });

  test('fromVideoId with a start time waits for a view', () async {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: 'dQw4w9WgXcQ',
      startSeconds: 30,
    );
    await pump();
    expect(platform.params, isEmpty);
    controller.customControls = true;
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single..emit(const ReadyEvent());
    await pump();
    expect(host.calls, isEmpty, reason: 'whole seconds avoid a second load');
    final vars = platform.params.single.playerVars;
    expect(vars['start'], 30);
    expect(vars.containsKey('end'), isFalse);
    expect(vars['controls'], 0);
  });

  test('fromVideoId with a fractional start time cues after ready', () async {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: 'dQw4w9WgXcQ',
      startSeconds: 12.5,
    );
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single..emit(const ReadyEvent());
    await pump();
    expect(host.calls.single.$1, PlayerMethod.cueVideoById);
    expect(platform.params.single.playerVars.containsKey('start'), isFalse);
  });

  test('background color is part of host creation', () async {
    final controller = YoutubePlayerController()
      ..backgroundColor = const Color(0xFF112233);
    unawaited(controller.host);
    await pump();
    expect(platform.params.single.backgroundColor, const Color(0xFF112233));
  });

  test('custom controls turn off native controls and pointer events', () {
    final params = const YoutubePlayerParams(enableKeyboard: true)
        .toHostParams(customControls: true);
    expect(params.playerVars['controls'], 0);
    expect(params.playerVars['disablekb'], 1);
    expect(params.playerVars['fs'], 0);
    expect(params.pointerEvents, 'none');

    final defaults = const YoutubePlayerParams().toHostParams();
    expect(defaults.playerVars['controls'], 1);
    expect(defaults.playerVars['fs'], 1);
    expect(defaults.pointerEvents, 'initial');
  });

  testWidgets('controlsBuilder overlays exactly the player box', (
    tester,
  ) async {
    final controller = YoutubePlayerController();
    Size? overlaySize;
    await tester.pumpWidget(
      Directionality(
        textDirection: .ltr,
        child: Center(
          child: SizedBox(
            width: 320,
            child: YoutubePlayer(
              controller: controller,
              autoPlayWhenVisible: false,
              controlsBuilder: (context, value) {
                expect(context.ytController, same(controller));
                return LayoutBuilder(
                  builder: (_, constraints) {
                    overlaySize = constraints.biggest;
                    return const SizedBox.expand();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(controller.customControls, isTrue);
    expect(platform.params.single.pointerEvents, 'none');
    expect(overlaySize, const Size(320, 180));
    expect(tester.getSize(find.byType(YoutubePlayer)), const Size(320, 180));
  });

  test('convertUrlToId', () {
    const id = 'dQw4w9WgXcQ';
    for (final url in [
      id,
      'https://www.youtube.com/watch?v=$id&t=3',
      'https://m.youtube.com/watch?v=$id',
      'https://youtu.be/$id?si=x',
      'https://www.youtube.com/embed/$id',
      'https://www.youtube.com/shorts/$id',
      'https://www.youtube.com/live/$id',
      '  https://youtu.be/$id  ',
    ]) {
      expect(YoutubePlayerController.convertUrlToId(url), id, reason: url);
    }
    expect(
      YoutubePlayerController.convertUrlToId('https://example.com/watch?v=$id'),
      isNull,
    );
    expect(
      YoutubePlayerController.convertUrlToId('https://youtu.be/short'),
      isNull,
    );
  });

  test('params map to documented playerVars only', () {
    final vars = const YoutubePlayerParams(
      showControls: false,
      strictRelatedVideos: true,
      showVideoAnnotations: false,
      color: .red,
      widgetReferrer: 'https://example.com',
    ).toPlayerVars();
    expect(vars['controls'], 0);
    expect(vars['rel'], 0);
    expect(vars['iv_load_policy'], 3);
    expect(vars['color'], 'red');
    expect(vars['widget_referrer'], 'https://example.com');
    expect(vars.containsKey('origin'), isFalse);
    expect(vars.containsKey('modestbranding'), isFalse);
    expect(vars.containsKey('enablejsapi'), isFalse, reason: 'page forces it');
  });
}
