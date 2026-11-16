// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// A part of YouTube's own player UI, inside the embedded player.
///
/// Elements are matched by a CSS [selector] against the embed page. Built-in
/// elements cover both YouTube's classic (`.ytp-*`) and newer (`ytm*` /
/// `ytw*`) embed UIs. YouTube does not document these, so a built-in element
/// may stop matching when YouTube changes its markup; use
/// [PlayerElement.custom] to target anything else.
///
/// Showing, hiding and intercepting elements works on Android, iOS and macOS.
/// Browsers do not let a page reach into the cross-origin player iframe, so
/// it has no effect on the web.
@immutable
final class const PlayerElement._(
  /// A stable identifier. For [PlayerElement.custom] it is the selector.
  final String name,

  /// The CSS selector list (comma separated) that matches this element.
  final String selector,
) {
  /// An element of the embed page matched by a CSS [selector] list, e.g.
  /// `PlayerElement.custom('.ytp-chrome-top')`. Its [name] is the selector.
  const new custom(String selector) : this._(selector, selector);

  /// Resolves [name] back to a built-in element, or a new custom one whose
  /// selector is [name].
  ///
  /// Elements compare by identity, so compare [name]s to match a custom
  /// element created elsewhere.
  factory byName(String name) {
    for (final element in values) {
      if (element.name == name) return element;
    }
    if (name == unknown.name) return unknown;
    return PlayerElement.custom(name);
  }

  /// The YouTube logo in the control bar and the watermark in the corner.
  static const youtubeLogo = PlayerElement._(
    'youtubeLogo',
    '.ytp-youtube-button, .ytp-watermark, .ytp-small-redirect',
  );

  /// The "Watch on YouTube" button.
  static const watchOnYoutube = PlayerElement._(
    'watchOnYoutube',
    '.ytp-impression-link, .watch-on-youtube-button-wrapper',
  );

  /// The video title at the top.
  static const title = PlayerElement._(
    'title',
    '.ytp-title-text, '
        '.ytp-title-link, '
        '.ytmVideoInfoVideoTitle, '
        '.ytwPlayerFullscreenTopControlsFullscreenControlsVideoTitle',
  );

  /// The channel avatar next to the title.
  static const channel = PlayerElement._(
    'channel',
    '.ytp-title-channel, '
        '.ytp-title-channel-logo, '
        '.ytmVideoInfoChannelTitle, '
        '.ytmVideoInfoChannelContainer',
  );

  /// The share button.
  static const shareButton = PlayerElement._(
    'shareButton',
    '.ytp-share-button',
  );

  /// The watch later button.
  static const watchLaterButton = PlayerElement._(
    'watchLaterButton',
    '.ytp-watch-later-button',
  );

  /// The copy link button.
  static const copyLinkButton = PlayerElement._(
    'copyLinkButton',
    '.ytp-copylink-button, .fullscreen-action-menu .icon-link',
  );

  /// The "More videos" strip or button and the related videos panel it
  /// opens.
  static const moreVideos = PlayerElement._(
    'moreVideos',
    '.ytp-pause-overlay, '
        '.ytp-pause-overlay-container, '
        '.fullscreen-watch-next-entrypoint-wrapper, '
        'ytm-fullscreen-related-videos-entry-point-view-model, '
        '.ytFullscreenVideoRecommendationsHost',
  );

  /// A related or suggested video thumbnail, anywhere in the player.
  static const relatedVideo = PlayerElement._(
    'relatedVideo',
    '.ytp-videowall-still, '
        '.ytp-modern-videowall-still, '
        '.ytp-suggestion-link, '
        '.ytp-ce-video, '
        '.ytp-ce-playlist, '
        '.ytFullscreenVideoRecommendationsRecommendation',
  );

  /// The end screen shown when the video finishes.
  static const endScreen = PlayerElement._(
    'endScreen',
    '.ytp-endscreen-content, .ytp-ce-element',
  );

  /// The info cards button and teaser.
  static const infoCards = PlayerElement._(
    'infoCards',
    '.ytp-cards-button, .ytp-cards-teaser',
  );

  /// The right-click / long-press context menu.
  static const contextMenu = PlayerElement._('contextMenu', '.ytp-contextmenu');

  /// The source of a navigation that did not come from a tracked click,
  /// e.g. a script opening a window.
  static const unknown = PlayerElement._('unknown', '');

  /// Every built-in element (except [unknown]).
  static const values = [
    youtubeLogo,
    watchOnYoutube,
    title,
    channel,
    shareButton,
    watchLaterButton,
    copyLinkButton,
    moreVideos,
    relatedVideo,
    endScreen,
    infoCards,
    contextMenu,
  ];

  @override
  String toString() => 'PlayerElement($name)';
}
