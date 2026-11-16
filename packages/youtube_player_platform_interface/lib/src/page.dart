// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'types.dart';

/// Builds the self-contained HTML page that hosts the IFrame API player on
/// native platforms.
///
/// [origin] is the client identity the page is loaded under (scheme + host
/// of the base URL). It becomes the `origin` and `widget_referrer` player
/// vars unless the caller already set them.
///
/// The page talks to the host through one string bridge, discovered at
/// runtime:
/// * WebView2: `window.chrome.webview.postMessage`
/// * WKWebView / WebKitGTK: `webkit.messageHandlers.ypBridge.postMessage`
/// * Android WebView: `ypBridge.postMessage` (a `@JavascriptInterface`)
///
/// The host calls into the page with `window.__yp.recv(json)`.
String buildPlayerPage(YoutubeHostParams params, {required String origin}) {
  final config = {
    'host': params.host,
    'videoId': ?params.videoId,
    'vars': {
      ...params.playerVars,
      'enablejsapi': 1,
      'origin': params.playerVars['origin'] ?? origin,
      'widget_referrer': params.playerVars['widget_referrer'] ?? origin,
    },
    'tick': params.tickInterval.inMilliseconds,
    'pe': params.pointerEvents,
  };
  return _template.replaceFirst('__CONFIG__', _scriptSafeJson(config));
}

/// JSON that is safe to inline in a `<script>` element.
String _scriptSafeJson(Object value) =>
    jsonEncode(value)
        .replaceAll('<', r'\u003c')
        .replaceAll('\u2028', r'\u2028')
        .replaceAll('\u2029', r'\u2029');

const _template = r'''
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>
html,body,#c{margin:0;padding:0;width:100%;height:100%;overflow:hidden;background:transparent}
body{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none;-webkit-tap-highlight-color:transparent}
#c{position:relative}
#c:fullscreen,#c:-webkit-full-screen{background:#000}
#p{position:absolute;inset:0;width:100%;height:100%;border:0}
</style>
</head>
<body>
<div id="c"><div id="p"></div></div>
<script>
(() => {
  'use strict';
  const C = __CONFIG__;
  const w = window, d = document;
  const mh = w.webkit && w.webkit.messageHandlers && w.webkit.messageHandlers.ypBridge;
  const out = w.chrome && w.chrome.webview ? (s) => w.chrome.webview.postMessage(s)
    : mh ? (s) => mh.postMessage(s)
    : (s) => w.ypBridge.postMessage(s);
  const post = (m) => out(JSON.stringify(m));
  const box = d.getElementById('c');
  let p = null, ready = false, raf = 0, last = 0, running = false;

  const tick = () => {
    if (!ready) return;
    post({e: 'tick', d: [p.getCurrentTime(), p.getVideoLoadedFraction(), p.getDuration(), p.getVolume(), p.isMuted() ? 1 : 0]});
  };
  const loop = (t) => {
    raf = requestAnimationFrame(loop);
    if (t - last >= C.tick) { last = t; tick(); }
  };
  const clock = (on) => {
    if (on === running) return;
    running = on;
    if (on) { last = 0; raf = requestAnimationFrame(loop); }
    else { cancelAnimationFrame(raf); tick(); }
  };
  const state = (s) => {
    const m = {s};
    if (s === -1 || s === 1 || s === 5) {
      const v = typeof p.getVideoData === 'function' ? p.getVideoData() : null;
      if (v) m.v = {id: v.video_id || '', t: v.title || '', a: v.author || ''};
      m.du = p.getDuration();
    }
    post({e: 'state', d: m});
    clock(s === 1 || s === 3);
  };

  const page = {
    requestFullscreen() {
      const f = box.requestFullscreen || box.webkitRequestFullscreen;
      if (!f) return false;
      try {
        const r = f.call(box);
        return r && r.then ? r.then(() => true, () => false) : true;
      } catch (_) { return false; }
    },
    exitFullscreen() {
      const f = d.exitFullscreen || d.webkitExitFullscreen;
      if (f && (d.fullscreenElement || d.webkitFullscreenElement)) f.call(d);
    },
  };
  const retick = {seekTo: 1, setVolume: 1, mute: 1, unMute: 1};

  w.__yp = {
    recv(json) {
      const {i, m, a} = JSON.parse(json);
      let r;
      try {
        r = page[m] ? page[m]() : p[m].apply(p, a || []);
      } catch (x) {
        if (i != null) post({r: i, x: String(x)});
        return;
      }
      if (retick[m] && !running) setTimeout(tick, 50);
      if (i == null) return;
      Promise.resolve(r).then(
        (v) => post({r: i, v: v === undefined ? null : v}),
        (x) => post({r: i, x: String(x)}));
    },
  };

  w.onYouTubeIframeAPIReady = () => {
    p = new YT.Player('p', {
      width: '100%',
      height: '100%',
      host: C.host,
      videoId: C.videoId,
      playerVars: C.vars,
      events: {
        onReady() {
          ready = true;
          p.getIframe().style.pointerEvents = C.pe;
          post({e: 'ready'});
        },
        onStateChange: (e) => state(e.data),
        onPlaybackRateChange: (e) => post({e: 'rate', d: e.data}),
        onPlaybackQualityChange: (e) => post({e: 'quality', d: e.data}),
        onError: (e) => post({e: 'error', d: e.data}),
        onApiChange: () => post({e: 'api'}),
        onAutoplayBlocked: () => post({e: 'autoplayBlocked'}),
      },
    });
  };

  const api = d.createElement('script');
  api.src = 'https://www.youtube.com/iframe_api';
  api.async = true;
  api.onerror = () => post({e: 'loadError', d: 'Failed to load ' + api.src});
  d.head.appendChild(api);
})();
</script>
</body>
</html>
''';
