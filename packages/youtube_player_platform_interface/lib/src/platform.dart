// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'host.dart';
import 'types.dart';

/// The interface each youtube_player platform implementation extends.
///
/// Implementations register themselves through `registerWith` by assigning
/// [instance].
abstract class YoutubePlayerPlatform() extends PlatformInterface {
  this : super(token: _token);

  static final Object _token = Object();

  static YoutubePlayerPlatform? _instance;

  /// The registered implementation.
  static YoutubePlayerPlatform get instance =>
      _instance ??
      (throw UnsupportedError(
        'youtube_player has no implementation for this platform. '
        'Supported: Android, iOS, macOS, web, Windows, Linux.',
      ));

  /// Registers [instance] as the platform implementation.
  static set instance(YoutubePlayerPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Creates a player host and starts loading the player.
  Future<YoutubePlayerHost> createHost(YoutubeHostParams params);
}
