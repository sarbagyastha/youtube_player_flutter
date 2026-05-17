// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:youtube_player_iframe/youtube_player_iframe.dart' as iframe;

const _kDesktopUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

/// Defines player flags for [YoutubePlayer].
class YoutubePlayerFlags {
  /// If set to true, hides the controls.
  ///
  /// Default is false.
  final bool hideControls;

  /// Is set to true, controls will be visible at start.
  ///
  /// Default is false.
  final bool controlsVisibleAtStart;

  /// Define whether to auto play the video after initialization or not.
  ///
  /// Default is true.
  final bool autoPlay;

  /// Mutes the player initially.
  ///
  /// Default is false.
  final bool mute;

  /// If true, Live Playback controls will be shown instead of default ones.
  ///
  /// Default is false.
  final bool isLive;

  /// Hides thumbnail if true.
  ///
  /// Default is false.
  final bool hideThumbnail;

  /// Disables seeking video position when dragging horizontally.
  ///
  /// Default is false.
  final bool disableDragSeek;

  /// Enabling this causes the player to play the video again and again.
  ///
  /// Default is false.
  final bool loop;

  /// Enabling causes closed captions to be shown by default.
  ///
  /// Default is true.
  final bool enableCaption;

  /// Specifies the default language that the player will use to display captions.
  /// Set the parameter's value to an [ISO 639-1 two-letter language code](http://www.loc.gov/standards/iso639-2/php/code_list.php).
  ///
  /// Default is `en`.
  final String captionLanguage;

  /// Forces High Definition video quality when possible by setting a desktop user agent.
  ///
  /// Default is false.
  final bool forceHD;

  /// Specifies the default starting point of the video in seconds.
  ///
  /// Default is 0.
  final int startAt;

  /// Specifies the default end point of the video in seconds.
  final int? endAt;

  /// Has no effect. webview_flutter manages hybrid composition automatically.
  @Deprecated(
    'Has no effect. webview_flutter manages hybrid composition automatically.',
  )
  final bool useHybridComposition;

  /// Defines whether to show or hide the fullscreen button in the live player.
  ///
  /// Default is true.
  final bool showLiveFullscreenButton;

  /// Creates [YoutubePlayerFlags].
  const YoutubePlayerFlags({
    this.hideControls = false,
    this.controlsVisibleAtStart = false,
    this.autoPlay = true,
    this.mute = false,
    this.isLive = false,
    this.hideThumbnail = false,
    this.disableDragSeek = false,
    this.enableCaption = true,
    this.captionLanguage = 'en',
    this.loop = false,
    this.forceHD = false,
    this.startAt = 0,
    this.endAt,
    // ignore: deprecated_member_use_from_same_package
    this.useHybridComposition = true,
    this.showLiveFullscreenButton = true,
  });

  /// Copies new values assigned to the [YoutubePlayerFlags].
  YoutubePlayerFlags copyWith({
    bool? hideControls,
    bool? autoPlay,
    bool? mute,
    bool? isLive,
    bool? hideThumbnail,
    bool? disableDragSeek,
    bool? loop,
    bool? enableCaption,
    bool? forceHD,
    String? captionLanguage,
    int? startAt,
    int? endAt,
    bool? controlsVisibleAtStart,
    // ignore: deprecated_member_use_from_same_package
    @Deprecated('Has no effect.') bool? useHybridComposition,
    bool? showLiveFullscreenButton,
  }) {
    return YoutubePlayerFlags(
      autoPlay: autoPlay ?? this.autoPlay,
      captionLanguage: captionLanguage ?? this.captionLanguage,
      disableDragSeek: disableDragSeek ?? this.disableDragSeek,
      enableCaption: enableCaption ?? this.enableCaption,
      hideControls: hideControls ?? this.hideControls,
      hideThumbnail: hideThumbnail ?? this.hideThumbnail,
      isLive: isLive ?? this.isLive,
      loop: loop ?? this.loop,
      mute: mute ?? this.mute,
      forceHD: forceHD ?? this.forceHD,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      controlsVisibleAtStart:
          controlsVisibleAtStart ?? this.controlsVisibleAtStart,
      // ignore: deprecated_member_use_from_same_package
      useHybridComposition: useHybridComposition ?? this.useHybridComposition,
      showLiveFullscreenButton:
          showLiveFullscreenButton ?? this.showLiveFullscreenButton,
    );
  }

  /// Converts this flags object to [iframe.YoutubePlayerParams] for the iframe controller.
  iframe.YoutubePlayerParams toParams() {
    return iframe.YoutubePlayerParams(
      mute: mute,
      enableCaption: enableCaption,
      captionLanguage: captionLanguage,
      loop: loop,
      // Always hide native controls — Flutter overlay controls are used instead.
      showControls: false,
      // Always hide native fullscreen button — FullScreenButton widget is used.
      showFullscreenButton: false,
      playsInline: true,
      privacyEnhancedMode: true,
      userAgent: forceHD ? _kDesktopUserAgent : null,
    );
  }
}
