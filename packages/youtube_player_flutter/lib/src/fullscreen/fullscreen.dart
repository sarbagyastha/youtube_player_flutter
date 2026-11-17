// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:youtube_player/youtube_player.dart';

/// Fullscreen state of a `YoutubePlayer` from this package.
///
/// On Android, iOS and macOS fullscreen is presented by Flutter, so the
/// player's controls stay visible. On the web it is the browser's fullscreen,
/// which must be started from a user gesture. Get it with
/// [YoutubeFullScreen.of]. Its value is `true` while fullscreen.
abstract interface class YoutubeFullScreenController
    implements ValueListenable<bool> {
  /// Whether the player is fullscreen.
  bool get isFullScreen;

  /// Presents the player fullscreen.
  ///
  /// With [lock], the default, the player stays fullscreen when the device
  /// rotates back to portrait, and on Android and iOS the orientation follows
  /// [YoutubePlayerParams.fullscreenOrientation]. Rotation-triggered
  /// fullscreen (`YoutubePlayer.autoFullScreen`) is unlocked.
  void enter({bool lock = true});

  /// Returns the player to its inline position.
  void exit();

  /// Calls [exit] when fullscreen, otherwise [enter].
  void toggle();
}

/// Provides the [YoutubeFullScreenController] of the enclosing player.
///
/// Available to the default controls and to `YoutubePlayer.builder`.
class const YoutubeFullScreen({
  super.key,
  required YoutubeFullScreenController super.notifier,
  required super.child,
}) extends InheritedNotifier<YoutubeFullScreenController> {
  /// Provides the fullscreen controller to [child].
  this;

  /// The nearest fullscreen controller.
  ///
  /// With [listen], the default, [context] rebuilds when fullscreen changes.
  static YoutubeFullScreenController of(
    BuildContext context, {
    bool listen = true,
  }) {
    final controller = maybeOf(context, listen: listen);
    assert(
      controller != null,
      'No YoutubeFullScreen found above this context. It is provided inside '
      'YoutubePlayer from youtube_player_flutter.',
    );
    return controller!;
  }

  /// The nearest fullscreen controller, if any.
  static YoutubeFullScreenController? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) => listen
      ? context
            .dependOnInheritedWidgetOfExactType<YoutubeFullScreen>()
            ?.notifier
      : context.getInheritedWidgetOfExactType<YoutubeFullScreen>()?.notifier;
}

/// Backing implementation used by the player widget, which supplies the
/// actual route handling through [onEnter] and [onExit].
final class FullScreenNotifier({
  required final void Function({required bool lock}) onEnter,
  required final VoidCallback onExit,
}) extends ValueNotifier<bool> implements YoutubeFullScreenController {
  this : super(false);

  /// Whether the current fullscreen was entered with `lock: true`.
  bool isLocked = false;

  @override
  bool get isFullScreen => value;

  @override
  void enter({bool lock = true}) {
    if (value) {
      // Upgrading rotation-triggered fullscreen to an explicit one.
      isLocked = isLocked || lock;
      return;
    }
    isLocked = lock;
    onEnter(lock: lock);
  }

  @override
  void exit() {
    if (value) onExit();
  }

  @override
  void toggle() => value ? exit() : enter();
}

/// The fullscreen page: opaque, so the page beneath stops painting and its
/// platform views stop compositing, and instant, so no opacity layer is ever
/// composited over the platform view.
final class FullScreenRoute({required final WidgetBuilder builder})
    extends PageRoute<void> {
  this;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => .zero;

  @override
  Duration get reverseTransitionDuration => .zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);
}

/// Whether system UI and orientation can be controlled (Android and iOS).
bool get isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == .android || defaultTargetPlatform == .iOS);

/// Hides system bars and, when [lock]ed, applies [orientation].
/// No-op on the web and desktop.
void applyFullScreenSystemUi({
  required bool lock,
  required FullscreenOrientation orientation,
}) {
  if (!isMobilePlatform) return;
  SystemChrome.setEnabledSystemUIMode(.immersiveSticky);
  if (!lock) return;
  switch (orientation) {
    case .landscape:
      SystemChrome.setPreferredOrientations(const [
        .landscapeLeft,
        .landscapeRight,
      ]);
    case .auto:
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    case .unchanged:
      break;
  }
}

/// Restores system bars and orientations. No-op on the web and desktop.
void restoreSystemUi() {
  if (!isMobilePlatform) return;
  SystemChrome.setEnabledSystemUIMode(.edgeToEdge);
  SystemChrome.setPreferredOrientations(const []);
}
