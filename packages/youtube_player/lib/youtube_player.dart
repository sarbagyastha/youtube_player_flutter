// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Play YouTube videos inline in Flutter, through the official
/// [IFrame Player API](https://developers.google.com/youtube/iframe_api_reference).
///
/// Works on Android, iOS, macOS and the web. Add the package and you are set;
/// the right implementation is picked for each platform automatically.
///
/// ## Getting started
///
/// Create a [YoutubePlayerController], show it with a [YoutubePlayer], and
/// [YoutubePlayerController.close] it when you are done:
///
/// ```dart
/// final controller = YoutubePlayerController.fromVideoId(
///   videoId: 'M7lc1UVf-VE',
///   autoPlay: true,
///   params: const YoutubePlayerParams(mute: true),
/// );
///
/// // In build():
/// YoutubePlayer(controller: controller);
///
/// // In dispose():
/// controller.close();
/// ```
///
/// ## What's in here
///
/// * [YoutubePlayerController]: commands (play, seek, volume, playlists,
///   captions, ...) and the current state. Commands return immediately and
///   getters return plain values, so there is no `await` and it is safe to
///   read them in `build()`. Calls made before the player is ready are queued.
/// * [YoutubePlayer]: the widget that displays a controller's player.
/// * [YoutubePlayerParams]: player configuration, such as controls, captions,
///   loop and the client identity ([YoutubePlayerParams.appId]) YouTube
///   requires.
/// * [YoutubeValueBuilder], [YoutubePlayerControllerProvider] and
///   `BuildContext.ytController`: rebuild on player changes and share a
///   controller down the tree.
/// * [YoutubePlayer.controlsBuilder]: replace YouTube's controls with your own
///   Flutter widgets.
/// * [YoutubePlayerController.elementVisibility] and
///   [YoutubePlayerController.onNavigationRequest]: hide parts of YouTube's UI
///   and decide where link and button clicks go. Android, iOS and macOS only.
///
/// ## Good to know
///
/// * Autoplay waits until at least half of the player is visible, and only one
///   player autoplays at a time, as YouTube requires. Turn this off with
///   [YoutubePlayer.autoPlayWhenVisible].
/// * Fullscreen is the platform's own; the player's fullscreen button works
///   without any setup.
/// * On iOS and macOS the app must use Swift Package Manager (Flutter's
///   default). On macOS, enable the `com.apple.security.network.client`
///   entitlement.
library;

export 'package:youtube_player_platform_interface/youtube_player_platform_interface.dart'
    show
        FullscreenOrientation,
        NavigationRequest,
        PlayerElement,
        PlayerState,
        SphericalProperties,
        VideoData,
        YoutubeError,
        YoutubeLoadError;

export 'src/controller.dart'
    show
        ElementVisibility,
        NavigationDecision,
        NavigationRequestHandler,
        YoutubePlayerController;
export 'src/iframe_api.dart';
export 'src/params.dart';
export 'src/value.dart';
export 'src/widgets/value_builder.dart';
export 'src/widgets/youtube_player.dart';
