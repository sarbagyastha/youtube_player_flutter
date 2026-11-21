import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart';

final class FakeBridgeHost({super.replyTimeout}) extends BridgeHost {
  final sent = <Map<String, Object?>>[];
  var nativeDisposed = false;

  @override
  void sendToPage(String json) =>
      sent.add(jsonDecode(json) as Map<String, Object?>);

  @override
  void disposeNative() => nativeDisposed = true;

  void page(Object message) => receiveFromPage(jsonEncode(message));

  void navigate(String url) => emitNavigation(url);

  @override
  bool get supportsElementControl => true;

  @override
  void setBackgroundColor(Color color) {}

  @override
  void exitFullscreen() {}

  @override
  Widget buildView({gestureRecognizers = const {}}) => const SizedBox();
}

void main() {
  group('PlayerEvent.fromWire', () {
    test('decodes every event', () {
      expect(PlayerEvent.fromWire('ready', null), isA<ReadyEvent>());
      expect(
        PlayerEvent.fromWire('rate', 1.5),
        isA<PlaybackRateChangeEvent>().having((e) => e.rate, 'rate', 1.5),
      );
      expect(
        PlayerEvent.fromWire('error', 150),
        isA<ErrorEvent>().having(
          (e) => e.error,
          'error',
          YoutubeError.notEmbeddable,
        ),
      );
      expect(
        PlayerEvent.fromWire('error', 153),
        isA<ErrorEvent>().having(
          (e) => e.error,
          'error',
          YoutubeError.missingClientIdentity,
        ),
      );
      expect(
        PlayerEvent.fromWire('autoplayBlocked', null),
        isA<AutoplayBlockedEvent>(),
      );
      expect(PlayerEvent.fromWire('api', null), isA<ApiChangeEvent>());
      expect(PlayerEvent.fromWire('nope', null), isNull);
      expect(PlayerEvent.fromWire('rate', 'bad'), isNull);
    });

    test('decodes state with video data', () {
      final event = PlayerEvent.fromWire('state', {
        's': 1,
        'v': {'id': 'abc', 't': 'Title', 'a': 'Author'},
        'du': 12.5,
      });
      expect(event, isA<StateChangeEvent>());
      event as StateChangeEvent;
      expect(event.state, PlayerState.playing);
      expect(
        event.videoData,
        const VideoData(videoId: 'abc', title: 'Title', author: 'Author'),
      );
      expect(event.duration, 12.5);
    });

    test('decodes compact tick', () {
      final event =
          PlayerEvent.fromWire('tick', [3.25, 0.5, 100, 80, 1]) as TickEvent;
      expect(event.currentTime, 3.25);
      expect(event.loadedFraction, 0.5);
      expect(event.duration, 100);
      expect(event.volume, 80);
      expect(event.muted, isTrue);
    });
  });

  group('BridgeHost', () {
    test('fire-and-forget calls carry no id', () async {
      final host = FakeBridgeHost();
      host.call(PlayerMethod.seekTo, [10, true]);
      expect(host.sent.single, {
        'm': 'seekTo',
        'a': [10, true],
      });
    });

    test('queries correlate replies by id', () async {
      final host = FakeBridgeHost();
      final a = host.query(PlayerMethod.getPlaylist);
      final b = host.query(PlayerMethod.getVideoUrl);
      await Future<void>.delayed(Duration.zero);
      host.page({'r': 1, 'v': 'https://youtu.be/x'});
      host.page({
        'r': 0,
        'v': ['a', 'b'],
      });
      expect(await a, ['a', 'b']);
      expect(await b, 'https://youtu.be/x');
    });

    test('query errors and timeouts surface', () async {
      final host = FakeBridgeHost(
        replyTimeout: const Duration(milliseconds: 20),
      );
      final failing = host.query(PlayerMethod.getOptions);
      await Future<void>.delayed(Duration.zero);
      host.page({'r': 0, 'x': 'TypeError'});
      await expectLater(failing, throwsStateError);
      await expectLater(
        host.query(PlayerMethod.getOptions),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('events, navigations and disposal', () async {
      final host = FakeBridgeHost();
      final events = <PlayerEvent>[];
      final urls = <NavigationRequest>[];
      host.events.listen(events.add);
      host.navigations.listen(urls.add);
      host.page({'e': 'ready'});
      host.page({'e': 'unknown'});
      host.receiveFromPageForTest('not json');
      host.navigate('https://www.youtube.com/watch?v=abc');
      await Future<void>.delayed(Duration.zero);
      expect(events.single, isA<ReadyEvent>());
      expect(urls.single.uri!.queryParameters['v'], 'abc');
      expect(urls.single.element, PlayerElement.unknown);
      expect(urls.single.clickId, isNull);

      final pending = expectLater(
        host.query(PlayerMethod.getPlaylist),
        throwsStateError,
      );
      await Future<void>.delayed(Duration.zero);
      host.dispose();
      await pending;
      expect(host.nativeDisposed, isTrue);
      expect(await host.query(PlayerMethod.getPlaylist), isNull);
    });

    test('delivers page messages on a later event-loop turn', () async {
      final host = FakeBridgeHost();
      final events = <PlayerEvent>[];
      host.events.listen(events.add);
      host.page({'e': 'ready'});
      host.page({
        'e': 'state',
        'd': {'s': 2},
      });
      // Not synchronously, and not from microtasks alone: Native Interop
      // callbacks run outside the isolate's message loop.
      await Future<void>.microtask(() {});
      expect(events, isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(events, [isA<ReadyEvent>(), isA<StateChangeEvent>()]);

      host
        ..page({'e': 'ready'})
        ..dispose();
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(2));
    });
  });

  group('element control', () {
    test('click messages become navigation requests', () async {
      final host = FakeBridgeHost();
      final requests = <NavigationRequest>[];
      host.navigations.listen(requests.add);
      host.page({
        'e': 'click',
        'd': {'id': 0, 'n': 'youtubeLogo', 'u': 'https://www.youtube.com/'},
      });
      host.page({
        'e': 'click',
        'd': {'id': 1, 'n': 'shareButton', 'u': ''},
      });
      host.page({
        'e': 'click',
        'd': {'id': 2, 'n': '.my-thing', 'u': ''},
      });
      host.page({
        'e': 'click',
        'd': {'n': 'title', 'u': ''},
      });
      await Future<void>.delayed(Duration.zero);
      expect(requests.map((r) => (r.uri, r.element.name, r.clickId)), [
        (Uri.parse('https://www.youtube.com/'), 'youtubeLogo', null),
        (null, 'shareButton', 1),
        (null, '.my-thing', 2),
      ]);
      expect(requests[1].element, same(PlayerElement.shareButton));
    });

    test('hiding and resolving call the page', () {
      final host = FakeBridgeHost();
      host.setHiddenElements({
        PlayerElement.shareButton,
        const PlayerElement.custom('.x'),
      });
      host.resolveClick(3, allow: true);
      expect(host.sent, [
        {
          'm': 'setHidden',
          'a': [
            ['.ytp-share-button', '.x'],
          ],
        },
        {
          'm': 'resolveClick',
          'a': [3, true],
        },
      ]);
    });

    test('PlayerElement.byName round-trips', () {
      for (final element in PlayerElement.values) {
        expect(PlayerElement.byName(element.name), same(element));
      }
      expect(PlayerElement.byName('unknown'), PlayerElement.unknown);
      expect(PlayerElement.byName('.a b').selector, '.a b');
    });

    test('frame script embeds config safely', () {
      final script = buildFrameScript(
        hidden: {PlayerElement.youtubeLogo},
        customElements: {const PlayerElement.custom('</script><b>')},
        interceptButtons: true,
      );
      expect(script, isNot(contains('__CONFIG__')));
      expect(script, isNot(contains('</script><b>')));
      expect(
        script,
        contains(
          '"hidden":[".ytp-youtube-button, .ytp-watermark, '
          '.ytp-small-redirect"]',
        ),
      );
      expect(script, contains('"ib":true'));
      expect(script, contains('"n":"shareButton"'));
      expect(script, isNot(contains('"n":"unknown"')));
    });

    test('player page relays the frame and starts hidden', () {
      final html = buildPlayerPage(
        const YoutubeHostParams(
          playerVars: {},
          hiddenElements: {PlayerElement.title},
        ),
      );
      expect(html, contains('"hidden":["${PlayerElement.title.selector}"]'));
      expect(html, contains("post({e: 'click'"));
      expect(html, contains('setHidden(s)'));
      expect(html, contains('resolveClick(id, allow)'));
    });
  });

  group('buildPlayerPage', () {
    test('injects config safely and fills identity', () {
      final html = buildPlayerPage(
        const YoutubeHostParams(
          playerVars: {'hl': '</script><script>alert(1)</script>'},
          videoId: 'abc',
        ),
        origin: 'https://np.com.example.app',
      );
      expect(html, isNot(contains('</script><script>alert(1)')));
      expect(html, contains(r'\u003c/script>'));
      expect(html, contains('"origin":"https://np.com.example.app"'));
      expect(html, contains('"widget_referrer":"https://np.com.example.app"'));
      expect(html, contains('"enablejsapi":1'));
      expect(html, contains('"videoId":"abc"'));
      expect(html, isNot(contains('__CONFIG__')));
    });

    test('keeps caller supplied origin', () {
      final html = buildPlayerPage(
        const YoutubePlayerHostParamsFixture().params,
        origin: 'https://ignored',
      );
      expect(html, contains('"origin":"https://custom"'));
      expect(html, isNot(contains('"videoId"')));
    });

    test('falls back to location.origin without an origin', () {
      final html = buildPlayerPage(const YoutubeHostParams(playerVars: {}));
      expect(html, isNot(contains('"origin":')));
      expect(html, contains('C.vars.origin || location.origin'));
      expect(
        html,
        contains('<link rel="preconnect" href="https://www.youtube.com">'),
      );
      expect(html, isNot(contains('__HOST__')));
    });
  });
}

extension on FakeBridgeHost {
  // ignore: invalid_use_of_protected_member
  void receiveFromPageForTest(String raw) => receiveFromPage(raw);
}

class const YoutubePlayerHostParamsFixture() {
  YoutubeHostParams get params =>
      const YoutubeHostParams(playerVars: {'origin': 'https://custom'});
}
