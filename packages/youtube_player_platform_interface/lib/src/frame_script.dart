// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'element.dart';
import 'script_json.dart';

/// Builds the script a native host injects into the YouTube embed iframe
/// (at document start, in every frame of the YouTube hosts).
///
/// The script:
/// * keeps the video filling its frame (letterboxed by the browser), since
///   YouTube's own sizing can go stale after a resize;
/// * hides the [hidden] elements with a style sheet, so they never flash;
/// * reports every link click with the matching element instead of letting
///   it navigate, so the app decides what happens;
/// * when [interceptButtons] is set, holds clicks on other matched elements
///   (e.g. the share button) until the app resolves them;
/// * applies `hidden` and `resolve` messages from the player page.
///
/// It talks only to the player page, via `postMessage`. Clicks are matched
/// against [PlayerElement.values], [customElements] and [hidden].
String buildFrameScript({
  Set<PlayerElement> hidden = const {},
  Set<PlayerElement> customElements = const {},
  bool interceptButtons = false,
}) {
  final elements = {...PlayerElement.values, ...customElements, ...hidden};
  final config = {
    'els': [
      for (final e in elements)
        if (e.selector.isNotEmpty) {'n': e.name, 's': e.selector},
    ],
    'hidden': [
      for (final e in hidden)
        if (e.selector.isNotEmpty) e.selector,
    ],
    'ib': interceptButtons,
  };
  return _template.replaceFirst('__CONFIG__', scriptSafeJson(config));
}

const _template = r'''
(() => {
  'use strict';
  const w = window, d = document;
  if (w === w.top || w.__ypFrame || !/^\/embed\//.test(location.pathname) ||
    !/^www\.youtube(-nocookie)?\.com$/.test(location.hostname)) return;
  w.__ypFrame = 1;
  const C = __CONFIG__;
  const send = (m) => w.parent.postMessage(m, '*');

  const style = d.createElement('style');
  const base = '.html5-video-container{width:100%!important;height:100%!important}' +
    'video.html5-main-video{left:0!important;top:0!important;' +
    'width:100%!important;height:100%!important;object-fit:contain!important}';
  const css = (s) => {
    // One rule per element, so an invalid selector drops only its own.
    style.textContent = [base, ...s.map((x) => x + '{display:none!important}')].join('\n');
  };
  const attach = () => {
    const root = d.head || d.documentElement;
    if (!root) return false;
    if (style.parentNode !== root) root.appendChild(style);
    return true;
  };
  css(C.hidden);
  if (!attach()) {
    const o = new MutationObserver(() => { if (attach()) o.disconnect(); });
    o.observe(d, {childList: true});
  }
  d.addEventListener('DOMContentLoaded', attach);

  // The innermost matching element wins (e.g. a related video inside the
  // end screen).
  const match = (t) => {
    let name = null, node = null;
    for (const e of C.els) {
      let n = null;
      try { n = t.closest(e.s); } catch (_) {}
      if (n && (!node || node.contains(n))) { name = e.n; node = n; }
    }
    return name;
  };

  const held = new Map();
  let next = 0, replaying = false;
  w.addEventListener('click', (ev) => {
    if (replaying) return;
    const t = ev.target instanceof Element ? ev.target
      : ev.target && ev.target.parentElement;
    if (!t) return;
    const a = t.closest('a[href]');
    const url = a && /^https?:/i.test(a.href) ? a.href : '';
    const name = match(t);
    if (!url && !(name && C.ib)) return;
    ev.preventDefault();
    ev.stopImmediatePropagation();
    const id = next++;
    if (!url) held.set(id, t);
    send({__yp: 'click', id, n: name || 'unknown', u: url});
  }, true);

  w.addEventListener('message', (e) => {
    const m = e.data;
    if (e.source !== w.parent || !m || typeof m !== 'object') return;
    if (m.__yp === 'hidden' && Array.isArray(m.s)) {
      css(m.s);
      attach();
    } else if (m.__yp === 'resolve') {
      const el = held.get(m.id);
      held.delete(m.id);
      if (!el || !m.allow || !el.isConnected) return;
      replaying = true;
      try { el.click(); } finally { replaying = false; }
    }
  });

  send({__yp: 'frameReady'});
})();
''';
