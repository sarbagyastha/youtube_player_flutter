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
  final navController = StreamController<Uri>.broadcast(sync: true);
  final fullscreenController = StreamController<bool>.broadcast(sync: true);
  var disposed = false;
  var exitedFullscreen = false;

  void emit(PlayerEvent event) => eventController.add(event);

  @override
  Stream<PlayerEvent> get events => eventController.stream;

  @override
  Stream<Uri> get navigations => navController.stream;

  @override
  Stream<bool> get fullscreenChanges => fullscreenController.stream;

  @override
  Future<void> call(
    PlayerMethod method, [
    List<Object?> args = const [],
  ]) async => calls.add((method, args));

  @override
  Future<Object?> query(
    PlayerMethod method, [
    List<Object?> args = const [],
  ]) async {
    calls.add((method, args));
    return queryResults[method];
  }

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> exitFullscreen() async => exitedFullscreen = true;

  @override
  Widget buildView({
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = const {},
  }) => const SizedBox.expand();

  @override
  Future<void> dispose() async => disposed = true;
}

final class FakePlatform extends YoutubePlayerPlatform
    with MockPlatformInterfaceMixin {
  final hosts = <FakeHost>[];
  final params = <YoutubeHostParams>[];

  @override
  Future<YoutubePlayerHost> createHost(YoutubeHostParams params) async {
    this.params.add(params);
    return FakeHost()..let(hosts.add);
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
    unawaited(controller.playVideo());
    unawaited(controller.seekTo(seconds: 10, allowSeekAhead: true));
    unawaited(controller.setVolume(40));
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

    expect(await controller.currentTime, 12.5);
    expect(await controller.volume, 70);
    expect(await controller.isMuted, isTrue);
    expect(await controller.playbackRate, 1.5);
    expect(await controller.playerState, PlayerState.playing);
    expect(controller.metadata.title, 'T');
    expect(controller.metadata.duration, const Duration(minutes: 1));
    expect(states.single.position, const Duration(milliseconds: 12500));
    // Getters served from cache: no queries sent.
    expect(host.calls, isEmpty);

    host.emit(const StateChangeEvent(.cued));
    await pump();
    expect(controller.value.playbackRate, 1, reason: 'cue resets the rate');
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

  test('related video links load in place; custom handler wins', () async {
    final handled = <Uri>[];
    final controller = YoutubePlayerController(
      onLinkTap: (uri) {
        if (uri.host != 'example.com') return false;
        handled.add(uri);
        return true;
      },
    );
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single..emit(const ReadyEvent());

    host.navController.add(
      Uri.parse(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=emb_rel_end',
      ),
    );
    host.navController.add(Uri.parse('https://example.com/x'));
    await pump();
    await pump();
    expect(host.calls.single.$1, PlayerMethod.loadVideoById);
    expect(host.calls.single.$2, [
      {'videoId': 'dQw4w9WgXcQ'},
    ]);
    expect(handled.single.host, 'example.com');
    await controller.close();
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
    await controller.toggleFullScreen();
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
      await controller.cuePlaylist(list: ['a', 'b'], index: 1);
      await controller.loadPlaylist(list: ['PL123'], listType: .playlist);
      await controller.cueVideoById(videoId: 'x', startSeconds: 5);
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
    final pending = controller.playVideo();
    unawaited(controller.host);
    await pump();
    final host = platform.hosts.single;
    await controller.close();
    await pending;
    await controller.pauseVideo();
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
