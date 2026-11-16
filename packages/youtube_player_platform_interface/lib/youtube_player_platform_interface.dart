// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// The platform interface for the `youtube_player` plugin.
///
/// **Building an app?** You don't need this package; use `youtube_player`
/// instead. This package is for those who add `youtube_player` support to a
/// new platform, or want to replace an existing implementation.
///
/// ## Implementing a platform
///
/// 1. Extend [YoutubePlayerPlatform] and override
///    [YoutubePlayerPlatform.createHost], which creates a [YoutubePlayerHost]
///    for one player and starts loading it. Override
///    [YoutubePlayerPlatform.openExternal] if the platform can open links in
///    another app.
/// 2. Implement [YoutubePlayerHost]: calls in ([YoutubePlayerHost.call],
///    [YoutubePlayerHost.query]), events out ([YoutubePlayerHost.events],
///    [YoutubePlayerHost.navigations], [YoutubePlayerHost.fullscreenChanges]),
///    and the widget from [YoutubePlayerHost.buildView]. Hosts that load the
///    player page in a WebView can extend [BridgeHost], which handles message
///    encoding, request/reply matching and event decoding; the page script
///    comes from [buildFrameScript].
/// 3. Register the implementation by assigning [YoutubePlayerPlatform.instance]
///    from a `registerWith` method, and declare it in your `pubspec.yaml`:
///
/// ```yaml
/// flutter:
///   plugin:
///     implements: youtube_player
///     platforms:
///       windows:
///         dartPluginClass: WindowsYoutubePlayer
/// ```
///
/// Also in here are the types shared with the app-facing package: the player
/// enums, [PlayerEvent]s, [PlayerElement] and [NavigationRequest].
library;

export 'src/element.dart';
export 'src/enums.dart';
export 'src/events.dart';
export 'src/frame_script.dart';
export 'src/host.dart';
export 'src/page.dart';
export 'src/platform.dart';
export 'src/types.dart';
