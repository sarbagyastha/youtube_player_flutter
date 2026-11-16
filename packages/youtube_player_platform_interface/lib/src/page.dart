// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'frame_script.dart' show buildFrameScript;
import 'script_json.dart';
import 'types.dart';

/// Builds the self-contained HTML page that hosts the IFrame API player on
/// native platforms.
///
/// [origin] is the client identity the page is loaded under (scheme + host
/// of the base URL). It becomes the `origin` and `widget_referrer` player
/// vars unless the caller already set them. When omitted, the page uses its
/// own `location.origin`, which is the same identity because hosts load the
/// page under `https://<appId>/`.
///
/// The page talks to the host through one string bridge, discovered at
/// runtime:
/// * WebView2: `window.chrome.webview.postMessage`
/// * WKWebView / WebKitGTK: `webkit.messageHandlers.ypBridge.postMessage`
/// * Android WebView: `ypBridge.postMessage` (a `@JavascriptInterface`)
///
/// The host calls into the page with `window.__yp.recv(json)`.
///
/// When the host injects [buildFrameScript] into the player iframe, the page
/// relays its clicks as `click` messages and forwards `setHidden` /
/// `resolveClick` calls to it with `postMessage`.
String buildPlayerPage(YoutubeHostParams params, {String? origin}) {
  final vars = {...params.playerVars, 'enablejsapi': 1};
  if (origin != null) {
    vars['origin'] = params.playerVars['origin'] ?? origin;
    vars['widget_referrer'] = params.playerVars['widget_referrer'] ?? origin;
  }
  final config = {
    'host': params.host,
    'videoId': ?params.videoId,
    'vars': vars,
    'tick': params.tickInterval.inMilliseconds,
    'pe': params.pointerEvents,
    'hidden': [
      for (final e in params.hiddenElements)
        if (e.selector.isNotEmpty) e.selector,
    ],
  };
  return _template
      .replaceFirst('__HOST__', _attr(params.host))
      .replaceFirst('__CONFIG__', scriptSafeJson(config));
}

/// Escapes [value] for a double-quoted HTML attribute.
String _attr(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;');

const _template = r'''
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">
<meta name="referrer" content="strict-origin-when-cross-origin">
<link rel="preconnect" href="https://www.youtube.com">
<link rel="preconnect" href="__HOST__">
<link rel="preconnect" href="https://i.ytimg.com">
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
  let hidden = C.hidden;
  let p = null, ready = false, timer = 0, running = false, lastTick = '', lastVideo = '';
  C.vars.origin = C.vars.origin || location.origin;
  C.vars.widget_referrer = C.vars.widget_referrer || location.origin;

  const tick = () => {
    if (!ready) return;
    const d = [p.getCurrentTime(), p.getVideoLoadedFraction(), p.getDuration(), p.getVolume(), p.isMuted() ? 1 : 0];
    const key = d.join();
    if (key === lastTick) return;
    lastTick = key;
    post({e: 'tick', d});
  };
  const clock = (on) => {
    if (on === running) return;
    running = on;
    if (on) timer = setInterval(tick, C.tick);
    else { clearInterval(timer); tick(); setTimeout(tick, 250); }
  };
  const state = (s) => {
    const m = {s};
    if (s === -1 || s === 1 || s === 5) {
      const v = typeof p.getVideoData === 'function' ? p.getVideoData() : null;
      if (v) {
        const id = v.video_id || '', t = v.title || '', a = v.author || '';
        const key = id + '\n' + t + '\n' + a;
        if (key !== lastVideo) { lastVideo = key; m.v = {id, t, a}; }
      }
      m.du = p.getDuration();
    }
    // The player keeps or resets the rate on its own (e.g. across playlist
    // items); report what it actually is rather than guessing.
    if (typeof p.getPlaybackRate === 'function') m.r = p.getPlaybackRate();
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
    setHidden(s) {
      hidden = Array.isArray(s) ? s : [];
      toFrame({__yp: 'hidden', s: hidden});
    },
    resolveClick(id, allow) {
      toFrame({__yp: 'resolve', id, allow: !!allow});
    },
  };

  // The frame script (injected by the host into the player iframe) talks to
  // this page only through postMessage.
  const frame = () => {
    const f = p && typeof p.getIframe === 'function' ? p.getIframe() : null;
    return f ? f.contentWindow : null;
  };
  const toFrame = (m) => {
    const f = frame();
    if (f) f.postMessage(m, C.host);
  };
  w.addEventListener('message', (e) => {
    const m = e.data;
    if (!m || typeof m !== 'object' || typeof m.__yp !== 'string') return;
    if (e.origin !== C.host || !e.source || e.source !== frame()) return;
    if (m.__yp === 'click') post({e: 'click', d: {id: m.id, n: m.n, u: m.u}});
    else if (m.__yp === 'frameReady') toFrame({__yp: 'hidden', s: hidden});
  });
  const retick = {seekTo: 1, setVolume: 1, mute: 1, unMute: 1};

  // Without an initial video the IFrame API never fires onReady, so the
  // player is created from the first queueing call instead. Until the player
  // is ready, calls are buffered and replayed in order.
  const queueing = {cueVideoById: 1, loadVideoById: 1, cueVideoByUrl: 1,
    loadVideoByUrl: 1, cuePlaylist: 1, loadPlaylist: 1};
  const pending = [];

  const run = ({i, m, a}) => {
    let r;
    try {
      r = page[m] ? page[m].apply(page, a || []) : p[m].apply(p, a || []);
    } catch (x) {
      if (i != null) post({r: i, x: String(x)});
      return;
    }
    // The IFrame API getters update asynchronously, so settle with a few
    // ticks; unchanged ones are dropped.
    if (retick[m] && !running) for (const t of [50, 250, 1000]) setTimeout(tick, t);
    if (i == null) return;
    Promise.resolve(r).then(
      (v) => post({r: i, v: v === undefined ? null : v}),
      (x) => post({r: i, x: String(x)}));
  };

  const create = (first) => {
    const vars = Object.assign({}, C.vars);
    let videoId = C.videoId;
    if (!videoId && first) {
      const [x, index] = first.a || [];
      if (Array.isArray(x)) videoId = x[index || 0];
      else if (x && x.videoId) videoId = x.videoId;
      else if (x && x.mediaContentUrl) {
        const id = /\/(?:v|embed)\/([\w-]{11})/.exec(x.mediaContentUrl);
        if (id) videoId = id[1];
      } else if (x && x.list) {
        vars.listType = x.listType || 'playlist';
        vars.list = x.list;
      }
    }
    p = new YT.Player('p', {
      width: '100%',
      height: '100%',
      host: C.host,
      videoId,
      playerVars: vars,
      events: {
        onReady() {
          ready = true;
          p.getIframe().style.pointerEvents = C.pe;
          if (C.videoId) post({e: 'ready'});
          pending.splice(0).forEach(run);
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

  w.__yp = {
    recv(json) {
      const call = JSON.parse(json);
      if (ready || page[call.m]) return run(call);
      pending.push(call);
      if (!p && queueing[call.m]) create(call);
    },
  };

  w.onYouTubeIframeAPIReady = () => {
    if (C.videoId) create(null);
    else post({e: 'ready'});
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
