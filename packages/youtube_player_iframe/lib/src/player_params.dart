// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Defines player parameters for [YoutubePlayer].
class YoutubePlayerParams {
  /// Mutes the player.
  ///
  /// Default is false.
  final bool mute;

  /// Specifies the default language that the player will use to display captions.
  ///
  /// Set the parameter's value to an [ISO 639-1 two-letter language code](https://www.loc.gov/standards/iso639-2/php/code_list.php).
  ///
  /// This is ignored if [enableCaption] is false.
  final String captionLanguage;

  /// Setting the parameter's value to true causes closed captions to be shown by default,
  /// even if the user has turned captions off.
  ///
  /// Default is true.
  final bool enableCaption;

  /// Defines whether or not the player reacts to pointer events.
  ///
  /// See the [Mozilla Docs](https://developer.mozilla.org/en-US/docs/Web/CSS/pointer-events) for detail.
  final PointerEvents pointerEvents;

  /// This parameter specifies the color that will be used in the player's video progress bar to highlight the amount of the video that the viewer has already seen.
  /// Valid parameter values are red and white, and, by default, the player uses the color red in the video progress bar.
  ///
  /// See the [YouTube API blog](https://youtube-eng.googleblog.com/2011/08/coming-soon-dark-player-for-embeds_5.html) for more information about color options.
  final String color;

  /// This parameter indicates whether the video player controls are displayed.
  ///
  /// Default is true.
  final bool showControls;

  /// Setting the parameter's value to true causes the player to not respond to keyboard controls.
  ///
  /// Currently supported keyboard controls are:
  ///    Spacebar or [k]: Play / Pause
  ///    Arrow Left: Jump back 5 seconds in the current video
  ///    Arrow Right: Jump ahead 5 seconds in the current video
  ///    Arrow Up: Volume up
  ///    Arrow Down: Volume Down
  ///    [f]: Toggle full-screen display
  ///    [j]: Jump back 10 seconds in the current video
  ///    [l]: Jump ahead 10 seconds in the current video
  ///    [m]: Mute or unmute the video
  ///    [0-9]: Jump to a point in the video. 0 jumps to the beginning of the video, 1 jumps to the point 10% into the video, 2 jumps to the point 20% into the video, and so forth.
  ///
  /// The default value is 'true' for web & 'false' for mobile.
  final bool enableKeyboard;

  /// Setting the parameter's value to true enables the player to be controlled via IFrame or JavaScript Player API calls.
  ///
  /// Default true.
  final bool enableJavaScript;

  /// Setting this parameter to false prevents the fullscreen button from displaying in the player.
  ///
  /// Default false.
  final bool showFullscreenButton;

  /// Sets the player's interface language.
  /// The parameter value is an [ISO 639-1 two-letter language code](https://www.loc.gov/standards/iso639-2/php/code_list.php) or a fully specified locale.
  ///
  /// For example, fr and fr-ca are both valid values. Other language input codes, such as IETF language tags (BCP 47) might also be handled properly.
  ///
  /// The interface language is used for tooltips in the player and also affects the default caption track.
  /// Note that YouTube might select a different caption track language for a particular user based on the user's individual language preferences and the availability of caption tracks.
  final String interfaceLanguage;

  /// Setting the parameter's value to true causes video annotations to be shown by default,
  /// whereas setting to false causes video annotations to not be shown by default.
  ///
  /// Default is true.
  final bool showVideoAnnotations;

  /// In the case of a single video player, a setting of true causes the player to play the initial video again and again.
  ///
  /// In the case of a playlist player (or custom player), the player plays the entire playlist and then starts again at the first video.
  ///
  /// Default is false.
  final bool loop;

  /// This parameter provides an extra security measure for the IFrame API and is only supported for IFrame embeds.
  ///
  /// Specify your domain as the value.
  final String? origin;

  /// This parameter controls whether videos play inline or fullscreen in an HTML5 player on iOS.
  ///
  /// Default is true.
  final bool playsInline;

  /// Enabling this will ensure that related videos will come from the same channel as the video that was just played.
  ///
  /// Default is false.
  final bool strictRelatedVideos;

  /// The user agent for the player.
  final String? userAgent;

  /// Defines player parameters for the youtube player.
  const YoutubePlayerParams({
    this.mute = false,
    this.captionLanguage = 'en',
    this.enableCaption = true,
    this.pointerEvents = PointerEvents.initial,
    this.color = 'white',
    this.showControls = true,
    this.enableKeyboard = kIsWeb,
    this.enableJavaScript = true,
    this.showFullscreenButton = false,
    this.interfaceLanguage = 'en',
    this.showVideoAnnotations = true,
    this.loop = false,
    this.origin = 'https://www.youtube.com',
    this.playsInline = true,
    this.strictRelatedVideos = false,
    this.userAgent,
  });

  /// Creates [Map] representation of [YoutubePlayerParams].
  Map<String, dynamic> toMap() {
    return {
      'autoplay': 1,
      'mute': _boolean(mute),
      'cc_lang_pref': captionLanguage,
      'cc_load_policy': _boolean(enableCaption),
      'color': color,
      'controls': _boolean(showControls),
      'disablekb': _boolean(!enableKeyboard),
      'enablejsapi': _boolean(enableJavaScript),
      'fs': _boolean(showFullscreenButton),
      'hl': interfaceLanguage,
      'iv_load_policy': showVideoAnnotations ? 1 : 3,
      'loop': _boolean(loop),
      'modestbranding': '1',
      if (kIsWeb) ...{
        'origin': Uri.base.origin,
        'widget_referrer': Uri.base.origin,
      } else if (origin != null) ...{
        'origin': origin,
        'widget_referrer': origin,
      },
      'playsinline': _boolean(playsInline),
      'rel': _boolean(!strictRelatedVideos),
    };
  }

  /// The serialized JSON representation of the [YoutubePlayerParams].
  String toJson() => jsonEncode(toMap());

  int _boolean(bool value) => value ? 1 : 0;
}

/// The pointer events.
enum PointerEvents {
  /// The player reacts to pointer events, like hover and click.
  auto('auto'),

  /// The initial configuration for pointer event.
  ///
  /// In most cases, this resolves to [PointerEvents.auto].
  initial('initial'),

  /// The player does not react to any pointer events.
  none('none');

  /// Creates a [PointerEvents] for the [name].
  const PointerEvents(this.name);

  /// The name of the [PointerEvents].
  final String name;
}
