// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/src/controller.dart';

/// Defines player parameters for [YoutubePlayer].
class YoutubePlayerParams {
  /// Specifies whether the initial video will automatically start to play when the player loads.
  ///
  /// Default is true.
  ///
  /// Note: auto play might not always work on mobile devices.
  final bool autoPlay;

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

  /// This parameter specifies the time, measured in seconds from the start of the video,
  /// when the player should stop playing the video.
  ///
  /// Note that the time is measured from the beginning of the video and not from either the value of the start player parameter or the startSeconds parameter,
  /// which is used in YouTube Player API functions for loading or queueing a video.
  final Duration? endAt;

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
  final String origin;

  /// This parameter specifies a list of video IDs to play.
  ///
  /// If you specify a value, the first video that plays will be the [YoutubePlayerController.initialVideoId],
  /// and the videos specified in the playlist parameter will play thereafter.
  final List<String> playlist;

  /// This parameter controls whether videos play inline or fullscreen in an HTML5 player on iOS.
  ///
  /// Default is true.
  final bool playsInline;

  /// Enabling this will ensure that related videos will come from the same channel as the video that was just played.
  ///
  /// Default is false.
  final bool strictRelatedVideos;

  /// This parameter causes the player to begin playing the video at the given number of seconds from the start of the video.
  ///
  /// Note that similar to the [YoutubePlayerController.seekTo] function,
  /// the player will look for the closest keyframe to the time you specify.
  /// This means that sometimes the play head may seek to just before the requested time, usually no more than around two seconds.
  final Duration startAt;

  /// Enabling desktop mode.
  ///
  /// The player controls will be like the one seen on youtube.com
  ///
  /// Only effective on mobile devices.
  final bool desktopMode;

  /// Enables privacy enhanced embedding mode.
  ///
  /// More detail at https://support.google.com/youtube/answer/171780?hl=en
  ///
  /// Default is false.
  final bool privacyEnhanced;

  /// Defines player parameters for [YoutubePlayer].
  const YoutubePlayerParams({
    this.autoPlay = true,
    this.mute = false,
    this.captionLanguage = 'en',
    this.enableCaption = true,
    this.color = 'white',
    this.showControls = true,
    this.enableKeyboard = kIsWeb,
    this.enableJavaScript = true,
    this.endAt,
    this.showFullscreenButton = false,
    this.interfaceLanguage = 'en',
    this.showVideoAnnotations = true,
    this.loop = false,
    this.origin = 'https://www.youtube.com',
    this.playlist = const [],
    this.playsInline = true,
    this.strictRelatedVideos = false,
    this.startAt = Duration.zero,
    this.desktopMode = false,
    this.privacyEnhanced = false,
  });
}
