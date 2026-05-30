// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controller/youtube_player_controller.dart';
import '../enums/player_state.dart';
import '../enums/thumbnail_format.dart';
import '../enums/thumbnail_quality.dart';
import '../helpers/platform.dart';
import '../helpers/youtube_value_builder.dart';
import '../player_params.dart';
import '../player_value.dart';

/// A widget to play or stream Youtube Videos.
class YoutubePlayer extends StatefulWidget {
  /// A widget to play or stream Youtube Videos.
  const YoutubePlayer({
    super.key,
    required this.controller,
    this.aspectRatio = 16 / 9,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.backgroundColor,
    @Deprecated('Unused parameter. Use `YoutubePlayerParam.userAgent` instead.')
    this.userAgent,
    this.enableFullScreenOnVerticalDrag = true,
    this.keepAlive = false,
    this.autoFullScreen = true,
    this.thumbnailQuality = .high,
    this.thumbnailFormat = .webp,
    this.initParams,
    this.controlsBuilder,
  });

  /// The controller for this player.
  final YoutubePlayerController controller;

  /// Aspect ratio of the player. Defaults to `16 / 9`.
  final double aspectRatio;

  /// Which gestures should be consumed by the youtube player.
  ///
  /// It is possible for other gesture recognizers to be competing with the player on pointer
  /// events, e.g if the player is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The player will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// By default vertical and horizontal gestures are absorbed by the player.
  /// Passing an empty set will ignore the defaults.
  ///
  /// This is ignored on web.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// The background color of the [WebView].
  ///
  /// Default to [ColorScheme.surface].
  final Color? backgroundColor;

  /// The value used for the HTTP User-Agent: request header.
  ///
  /// When null the platform's webview default is used for the User-Agent header.
  ///
  /// By default `userAgent` is null.
  final String? userAgent;

  /// Enables switching full screen mode on vertical drag in the player.
  ///
  /// Default is true.
  final bool enableFullScreenOnVerticalDrag;

  /// Whether to keep the state of the player alive when it is not visible.
  final bool keepAlive;

  /// Whether to automatically enter fullscreen when the device rotates to landscape.
  ///
  /// Default is true.
  final bool autoFullScreen;

  /// If provided, used instead of [YoutubePlayerController.params] during initialization.
  /// Allows wrappers to force-override params (e.g. hide native controls) without
  /// mutating the user-supplied controller.
  final YoutubePlayerParams? initParams;

  /// Quality of the thumbnail shown while the iframe is loading.
  ///
  /// Defaults to [ThumbnailQuality.high].
  final ThumbnailQuality thumbnailQuality;

  /// Format of the thumbnail shown while the iframe is loading.
  ///
  /// Defaults to [ThumbnailFormat.webp].
  final ThumbnailFormat thumbnailFormat;

  /// If provided, renders custom controls on top of the player surface.
  /// On mobile, rendered inside the overlay portal. On desktop/web, rendered
  /// in a [Stack] on top of the [WebViewWidget].
  final Widget Function(BuildContext context, bool isFullscreen)?
  controlsBuilder;

  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // All live instances on mobile — used to exit fullscreen on sibling players
  // when a new player starts and to hide overlays during fullscreen.
  static final _instances = <_YoutubePlayerState>{};

  // Shared across all instances so players can hide their overlay when another
  // player is in fullscreen.
  static final _fullscreenCount = ValueNotifier<int>(0);

  // The instance that most recently transitioned into playing. Used by
  // autoFullScreen to ensure only the active player enters fullscreen on
  // device rotation, even when multiple players exist on the same screen.
  static _YoutubePlayerState? _mostRecentlyActive;

  late final YoutubePlayerController _controller;

  final _overlayController = OverlayPortalController();
  final _placeholderKey = GlobalKey();
  final _layerLink = LayerLink();
  Rect _playerRect = Rect.zero;

  StreamSubscription<YoutubePlayerValue>? _valueSub;
  PlayerState _lastPlayerState = .unknown;
  bool _prevFullscreen = false;
  bool _inFullscreenTransition = false;
  Timer? _transitionTimer;
  int _lastPlayingMs = 0;

  // Hot restart (debug only): the Dart isolate restarts without calling
  // dispose(), leaving old platform views alive on the native side.  The new
  // run assigns the same IDs (starting from 0), causing a recreating_view
  // exception.  Deferring WebViewWidget creation by one extra frame gives the
  // engine time to finish cleaning up stale views before new ones are created.
  bool _webViewReady = !kDebugMode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _initPlayer();

    if (isMobile) {
      _instances.add(this);
      WidgetsBinding.instance.addObserver(this);
      _valueSub = _controller.stream.listen(_onValueChanged);
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        // Second post-frame callback: one extra frame of delay so the engine
        // can process platform-view disposal from the previous run.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _webViewReady = true);
          if (isMobile) {
            _updatePlayerRect();
            _overlayController.show();
          }
        });
      } else {
        if (isMobile) {
          _updatePlayerRect();
          _overlayController.show();
        }
      }
    });
  }

  void _onValueChanged(YoutubePlayerValue value) {
    final isFullscreen = value.fullScreenOption.enabled;
    if (isFullscreen != _prevFullscreen) {
      _prevFullscreen = isFullscreen;
      if (isFullscreen) {
        _fullscreenCount.value++;
      } else {
        _fullscreenCount.value = (_fullscreenCount.value - 1).clamp(
          0,
          _fullscreenCount.value,
        );
      }
      _transitionTimer?.cancel();
      _inFullscreenTransition = false;
      // On button press the iframe fires StateChange=paused *before*
      // FullscreenButtonPressed, so _lastPlayerState is already paused by
      // the time we see the fullscreen toggle. The timestamp check catches
      // that case: if the video was playing within the last 500 ms, the
      // pause was iframe-generated, not user-initiated.
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final wasPlaying =
          _lastPlayerState == PlayerState.playing ||
          _lastPlayerState == PlayerState.buffering ||
          (nowMs - _lastPlayingMs) < 500;
      if (wasPlaying) {
        _inFullscreenTransition = true;
        _transitionTimer = Timer(const Duration(milliseconds: 600), () {
          _inFullscreenTransition = false;
        });
      }
    } else if (value.playerState != PlayerState.unknown) {
      if (_inFullscreenTransition && value.playerState == PlayerState.paused) {
        // Spurious pause from WebView relayout during fullscreen transition.
        if (mounted) _controller.playVideo();
      } else {
        if (value.playerState == PlayerState.playing ||
            value.playerState == PlayerState.buffering) {
          _lastPlayingMs = DateTime.now().millisecondsSinceEpoch;
          // When this player transitions into playing, exit fullscreen on any
          // other player that owns the overlay — but only on the transition
          // (not every frame while playing) to avoid unnecessary work.
          if (_lastPlayerState != PlayerState.playing &&
              _lastPlayerState != PlayerState.buffering) {
            _mostRecentlyActive = this;
            for (final other in _instances) {
              if (other != this && other._prevFullscreen) {
                other._controller.exitFullScreen();
              }
            }
          }
        }
        _lastPlayerState = value.playerState;
      }
    }
  }

  @override
  void didUpdateWidget(YoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.backgroundColor != oldWidget.backgroundColor) {
      _updateBackgroundColor(widget.backgroundColor);
    }
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _valueSub?.cancel();
    if (isMobile) {
      _instances.remove(this);
      WidgetsBinding.instance.removeObserver(this);
    }
    if (_mostRecentlyActive == this) _mostRecentlyActive = null;
    if (_prevFullscreen) {
      _fullscreenCount.value = (_fullscreenCount.value - 1).clamp(
        0,
        _fullscreenCount.value,
      );
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updatePlayerRect();
      if (!mounted || !widget.autoFullScreen) return;
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      final isLandscape = size.width > size.height;
      final opt = _controller.value.fullScreenOption;

      if (isLandscape && !opt.enabled) {
        // Only auto-fullscreen the most recently active player on rotation.
        // When _mostRecentlyActive is null no player has ever played, so all
        // players are eligible (single-player case still works as expected).
        if (_mostRecentlyActive == null || _mostRecentlyActive == this) {
          _controller.enterFullScreen(lock: false);
        }
      } else if (!isLandscape && opt.enabled && !opt.locked) {
        _controller.exitFullScreen(lock: false);
      }
    });
  }

  void _updatePlayerRect() {
    final box =
        _placeholderKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final newRect = box.localToGlobal(Offset.zero) & box.size;
    if (newRect != _playerRect) setState(() => _playerRect = newRect);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!isMobile) {
      final webView = _webViewReady
          ? WebViewWidget(
              controller: _controller.webViewController,
              gestureRecognizers: widget.gestureRecognizers,
            )
          : const SizedBox.expand();

      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            webView,
            if (widget.controlsBuilder != null)
              widget.controlsBuilder!(context, false),
            _PlayerLoadingOverlay(
              controller: _controller,
              backgroundColor: widget.backgroundColor,
              thumbnailQuality: widget.thumbnailQuality,
              thumbnailFormat: widget.thumbnailFormat,
            ),
          ],
        ),
      );
    }

    return YoutubeValueBuilder(
      controller: _controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        return PopScope(
          canPop: !value.fullScreenOption.enabled,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && value.fullScreenOption.enabled) {
              _controller.exitFullScreen();
            }
          },
          child: OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: (context) => _PlayerOverlayContent(
              controller: _controller,
              playerRect: _playerRect,
              layerLink: _layerLink,
              aspectRatio: widget.aspectRatio,
              backgroundColor: widget.backgroundColor,
              gestureRecognizers: widget.gestureRecognizers,
              enableFullScreenOnVerticalDrag:
                  widget.enableFullScreenOnVerticalDrag,
              controlsBuilder: widget.controlsBuilder,
              fullscreenCount: _fullscreenCount,
              thumbnailQuality: widget.thumbnailQuality,
              thumbnailFormat: widget.thumbnailFormat,
            ),
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _updatePlayerRect();
                  });
                  return CompositedTransformTarget(
                    link: _layerLink,
                    child: SizedBox.expand(key: _placeholderKey),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateBackgroundColor(Color? backgroundColor) {
    if (!mounted) return;
    if (!isMobile) return;
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    _controller.webViewController.setBackgroundColor(bgColor);
  }

  Future<void> _initPlayer() async {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateBackgroundColor(widget.backgroundColor);
    });

    if (widget.initParams != null) {
      await _controller.initWithParams(params: widget.initParams!);
    } else {
      await _controller.init();
    }
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}

class _PlayerOverlayContent extends StatelessWidget {
  const _PlayerOverlayContent({
    required this.controller,
    required this.playerRect,
    required this.layerLink,
    required this.backgroundColor,
    required this.gestureRecognizers,
    required this.enableFullScreenOnVerticalDrag,
    required this.fullscreenCount,
    this.aspectRatio = 16 / 9,
    this.controlsBuilder,
    this.thumbnailQuality = .high,
    this.thumbnailFormat = .webp,
  });

  final YoutubePlayerController controller;
  final Rect playerRect;
  final LayerLink layerLink;
  final Color? backgroundColor;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final bool enableFullScreenOnVerticalDrag;
  final double aspectRatio;
  final Widget Function(BuildContext context, bool isFullscreen)?
  controlsBuilder;
  final ValueListenable<int> fullscreenCount;
  final ThumbnailQuality thumbnailQuality;
  final ThumbnailFormat thumbnailFormat;

  @override
  Widget build(BuildContext context) {
    // Register a dependency on screen size so this widget rebuilds on rotation,
    // keeping the builder closure's screenSize in sync via didUpdateWidget.
    MediaQuery.sizeOf(context);

    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.fullScreenOption != n.fullScreenOption,
      builder: (context, value) {
        // Read screenSize here (not in the outer scope) so the builder always
        // uses the current dimensions, even when fullscreen and rotation fire
        // in the same frame before _PlayerOverlayContent has rebuilt.
        final screenSize = MediaQuery.sizeOf(context);
        final isFullscreen = value.fullScreenOption.enabled;

        // Guard against an uninitialised playerRect only when not in fullscreen.
        // In fullscreen we use absolute screen coordinates, so playerRect is
        // irrelevant — skipping the guard ensures the black background and
        // video layer are always rendered even when the inline placeholder has
        // not yet been measured (e.g. player scrolled off-screen).
        if (!isFullscreen &&
            (!playerRect.width.isFinite ||
                !playerRect.height.isFinite ||
                playerRect.isEmpty)) {
          return const SizedBox.shrink();
        }

        // Compute fullscreen dimensions that maintain the video aspect ratio.
        // Portrait: fit to screen width with letterbox (black bars top/bottom).
        // Landscape: fit to height (pillarbox) or width, whichever fills more.
        final double fsWidth;
        final double fsHeight;
        final double fsOffsetX;
        final double fsOffsetY;
        if (isFullscreen) {
          final isPortrait = screenSize.width < screenSize.height;
          if (isPortrait ||
              screenSize.width / screenSize.height <= aspectRatio) {
            fsWidth = screenSize.width;
            fsHeight = screenSize.width / aspectRatio;
          } else {
            fsHeight = screenSize.height;
            fsWidth = screenSize.height * aspectRatio;
          }
          fsOffsetX = (screenSize.width - fsWidth) / 2;
          fsOffsetY = (screenSize.height - fsHeight) / 2;
        } else {
          fsWidth = playerRect.width;
          fsHeight = playerRect.height;
          fsOffsetX = 0;
          fsOffsetY = 0;
        }

        // When fullscreen: use absolute screen coordinates so the layer is
        // always visible even when the inline placeholder is off-screen
        // (CompositedTransformFollower hides its child when the LayerLink
        // target is not composited, which happens for off-screen players).
        // When not fullscreen: CompositedTransformFollower tracks the
        // placeholder at the render layer so the overlay follows the player
        // accurately during scroll without per-frame Dart callbacks.
        Widget positionedLayer(Widget child) {
          if (isFullscreen) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: fsOffsetY,
              left: fsOffsetX,
              width: fsWidth,
              height: fsHeight,
              child: child,
            );
          }
          return Positioned(
            top: 0,
            left: 0,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              child: SizedBox(
                width: playerRect.width,
                height: playerRect.height,
                child: child,
              ),
            ),
          );
        }

        // Controls always cover the full screen in fullscreen so they can
        // render over letterbox/pillarbox areas, not just the video bounds.
        // Positioned.fill is used instead of an explicit size so the controls
        // always match the Stack (which already fills the screen via
        // StackFit.expand), avoiding any MediaQuery size mismatch.
        Widget positionedControls(Widget child) {
          if (isFullscreen) {
            return Positioned.fill(child: child);
          }
          return positionedLayer(child);
        }

        return ValueListenableBuilder<int>(
          valueListenable: fullscreenCount,
          builder: (context, count, _) {
            // Hide this player's layers when another player owns the fullscreen
            // so its overlay doesn't surface above the fullscreen background.
            // Opacity+IgnorePointer keeps the WebView alive (no reload on exit).
            final hideForOther = !isFullscreen && count > 0;
            Widget maybeHide(Widget w) => hideForOther
                ? IgnorePointer(child: Opacity(opacity: 0, child: w))
                : w;

            return Stack(
              fit: StackFit.expand,
              children: [
                _FullscreenBackground(isFullscreen: isFullscreen),
                positionedLayer(
                  maybeHide(
                    _YoutubeWebView(
                      controller: controller,
                      gestureRecognizers: gestureRecognizers,
                      enableFullScreenOnVerticalDrag:
                          enableFullScreenOnVerticalDrag,
                    ),
                  ),
                ),
                if (controlsBuilder != null)
                  positionedControls(
                    maybeHide(
                      Builder(
                        builder: (ctx) => controlsBuilder!(ctx, isFullscreen),
                      ),
                    ),
                  ),
                positionedLayer(
                  maybeHide(
                    _PlayerLoadingOverlay(
                      controller: controller,
                      backgroundColor: backgroundColor,
                      thumbnailQuality: thumbnailQuality,
                      thumbnailFormat: thumbnailFormat,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FullscreenBackground extends StatelessWidget {
  const _FullscreenBackground({required this.isFullscreen});

  final bool isFullscreen;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isFullscreen,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isFullscreen ? 1.0 : 0.0,
        child: const ColoredBox(color: Colors.black),
      ),
    );
  }
}

class _PlayerLoadingOverlay extends StatelessWidget {
  const _PlayerLoadingOverlay({
    required this.controller,
    required this.backgroundColor,
    this.thumbnailQuality = .high,
    this.thumbnailFormat = .webp,
  });

  final YoutubePlayerController controller;
  final Color? backgroundColor;
  final ThumbnailQuality thumbnailQuality;
  final ThumbnailFormat thumbnailFormat;

  @override
  Widget build(BuildContext context) {
    return YoutubeValueBuilder(
      controller: controller,
      buildWhen: (o, n) => o.playerState != n.playerState,
      builder: (context, value) {
        final isInitializing =
            value.playerState == PlayerState.unknown ||
            value.playerState == PlayerState.unStarted;
        final fallbackColor =
            backgroundColor ?? Theme.of(context).colorScheme.surface;
        final videoId = controller.key;
        return IgnorePointer(
          ignoring: !isInitializing,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isInitializing ? 1.0 : 0.0,
            child: videoId != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: fallbackColor),
                      Image.network(
                        YoutubePlayerController.getThumbnail(
                          videoId: videoId,
                          quality: thumbnailQuality,
                          format: thumbnailFormat,
                        ),
                        fit: BoxFit.cover,
                        frameBuilder:
                            (_, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                                child: child,
                              );
                            },
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ],
                  )
                : ColoredBox(color: fallbackColor),
          ),
        );
      },
    );
  }
}

class _YoutubeWebView extends StatelessWidget {
  const _YoutubeWebView({
    required this.controller,
    required this.gestureRecognizers,
    required this.enableFullScreenOnVerticalDrag,
  });

  final YoutubePlayerController controller;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final bool enableFullScreenOnVerticalDrag;

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() > 300) {
      velocity.isNegative
          ? controller.enterFullScreen()
          : controller.exitFullScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final webView = WebViewWidget(
      controller: controller.webViewController,
      gestureRecognizers: gestureRecognizers,
    );

    if (!enableFullScreenOnVerticalDrag) return webView;

    return GestureDetector(
      onVerticalDragEnd: _onVerticalDragEnd,
      child: webView,
    );
  }
}
