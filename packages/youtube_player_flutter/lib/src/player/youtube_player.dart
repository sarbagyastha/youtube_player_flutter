// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as iframe_pkg;

import '../enums/thumbnail_quality.dart';
import '../utils/errors.dart';
import '../utils/youtube_player_controller.dart';
import '../utils/youtube_player_flags.dart';
import '../widgets/widgets.dart';

/// A widget to play or stream YouTube videos using the official
/// [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference).
///
/// For live videos, set `isLive` to true in [YoutubePlayerFlags].
///
/// ```dart
/// YoutubePlayer(
///   controller: YoutubePlayerController(
///     initialVideoId: 'iLnmTe5Q2Qw',
///     flags: YoutubePlayerFlags(autoPlay: true),
///   ),
///   showVideoProgressIndicator: true,
///   progressIndicatorColor: Colors.amber,
///   progressColors: ProgressBarColors(
///     playedColor: Colors.amber,
///     handleColor: Colors.amberAccent,
///   ),
/// )
/// ```
class YoutubePlayer extends StatefulWidget {
  /// Creates [YoutubePlayer] widget.
  const YoutubePlayer({
    super.key,
    required this.controller,
    this.width,
    this.aspectRatio = 16 / 9,
    this.controlsTimeOut = const Duration(seconds: 3),
    this.bufferIndicator,
    Color? progressIndicatorColor,
    ProgressBarColors? progressColors,
    this.onReady,
    this.onEnded,
    this.liveUIColor = Colors.red,
    this.topActions,
    this.bottomActions,
    this.actionsPadding = const EdgeInsets.all(8.0),
    this.thumbnail,
    this.showVideoProgressIndicator = false,
  })  : progressColors = progressColors ?? const ProgressBarColors(),
        progressIndicatorColor = progressIndicatorColor ?? Colors.red;

  /// Controls the player.
  final YoutubePlayerController controller;

  /// {@template youtube_player_flutter.width}
  /// Width of the player. Defaults to the device's width.
  /// {@endtemplate}
  final double? width;

  /// {@template youtube_player_flutter.aspectRatio}
  /// Aspect ratio of the player. Determines height together with [width].
  ///
  /// Default is 16 / 9.
  /// {@endtemplate}
  final double aspectRatio;

  /// {@template youtube_player_flutter.controlsTimeOut}
  /// Duration for which the overlay controls stay visible after interaction.
  ///
  /// Default is 3 seconds.
  /// {@endtemplate}
  final Duration controlsTimeOut;

  /// {@template youtube_player_flutter.bufferIndicator}
  /// Custom buffering indicator. Defaults to a [CircularProgressIndicator].
  /// {@endtemplate}
  final Widget? bufferIndicator;

  /// {@template youtube_player_flutter.progressColors}
  /// Colors for the progress bar. Takes [ProgressBarColors].
  /// {@endtemplate}
  final ProgressBarColors progressColors;

  /// {@template youtube_player_flutter.progressIndicatorColor}
  /// Color of the thin progress indicator shown below the player when
  /// [showVideoProgressIndicator] is true.
  /// {@endtemplate}
  final Color progressIndicatorColor;

  /// {@template youtube_player_flutter.onReady}
  /// Called once the player is ready to accept control calls.
  /// {@endtemplate}
  final VoidCallback? onReady;

  /// {@template youtube_player_flutter.onEnded}
  /// Called when the video finishes playing.
  /// {@endtemplate}
  final void Function(YoutubeMetaData metaData)? onEnded;

  /// {@template youtube_player_flutter.liveUIColor}
  /// Accent color used in the live stream UI.
  /// {@endtemplate}
  final Color liveUIColor;

  /// {@template youtube_player_flutter.topActions}
  /// Widgets placed in the top action bar.
  /// {@endtemplate}
  final List<Widget>? topActions;

  /// {@template youtube_player_flutter.bottomActions}
  /// Widgets placed in the bottom action bar.
  /// {@endtemplate}
  final List<Widget>? bottomActions;

  /// {@template youtube_player_flutter.actionsPadding}
  /// Padding around [topActions] and [bottomActions].
  ///
  /// Default is EdgeInsets.all(8.0).
  /// {@endtemplate}
  final EdgeInsetsGeometry actionsPadding;

  /// {@template youtube_player_flutter.thumbnail}
  /// Thumbnail shown while the player is loading. Falls back to the video's
  /// default YouTube thumbnail if not set.
  /// {@endtemplate}
  final Widget? thumbnail;

  /// {@template youtube_player_flutter.showVideoProgressIndicator}
  /// Whether to show a thin progress indicator below the player.
  ///
  /// Default is false.
  /// {@endtemplate}
  final bool showVideoProgressIndicator;

  /// Converts a fully-qualified YouTube URL to its 11-character video ID.
  ///
  /// Returns null if the URL is not a recognised YouTube URL.
  static String? convertUrlToId(String url, {bool trimWhitespaces = true}) =>
      YoutubePlayerController.convertUrlToId(
        url,
        trimWhitespaces: trimWhitespaces,
      );

  /// Returns a thumbnail URL for [videoId].
  ///
  /// [quality] is one of the [ThumbnailQuality] constants.
  /// Set [webp] to false to get a JPEG URL instead.
  static String getThumbnail({
    required String videoId,
    String quality = ThumbnailQuality.standard,
    bool webp = true,
  }) =>
      YoutubePlayerController.getThumbnail(
        videoId: videoId,
        quality: quality,
        webp: webp,
      );

  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer> {
  late YoutubePlayerController _controller;
  late double _aspectRatio;
  bool _initialLoad = true;
  StreamSubscription<iframe_pkg.YoutubePlayerValue>? _endedSubscription;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller..addListener(_listener);
    _aspectRatio = widget.aspectRatio;
    _endedSubscription =
        _controller.iframeController.stream.listen(_onIframeValue);
  }

  @override
  void didUpdateWidget(YoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_listener);
      _endedSubscription?.cancel();
      _controller = widget.controller..addListener(_listener);
      _endedSubscription =
          _controller.iframeController.stream.listen(_onIframeValue);
    }
  }

  void _onIframeValue(iframe_pkg.YoutubePlayerValue iframeValue) {
    if (iframeValue.playerState == iframe_pkg.PlayerState.ended) {
      if (_controller.flags.loop) {
        _controller.load(
          _controller.metadata.videoId,
          startAt: _controller.flags.startAt,
          endAt: _controller.flags.endAt,
        );
      }
      widget.onEnded?.call(_controller.metadata);
    }
  }

  void _listener() async {
    if (_controller.value.isReady && _initialLoad) {
      _initialLoad = false;
      widget.onReady?.call();
      if (_controller.flags.controlsVisibleAtStart) {
        _controller.updateValue(
          _controller.value.copyWith(isControlsVisible: true),
        );
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _endedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.black,
      child: InheritedYoutubePlayer(
        controller: _controller,
        child: Container(
          color: Colors.black,
          width: widget.width ?? MediaQuery.of(context).size.width,
          child: _buildPlayer(
            errorWidget: Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 5.0),
                      Expanded(
                        child: Text(
                          errorString(
                            _controller.value.errorCode,
                            videoId: _controller.metadata.videoId.isNotEmpty
                                ? _controller.metadata.videoId
                                : _controller.initialVideoId,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 15.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Error Code: ${_controller.value.errorCode}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer({required Widget errorWidget}) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // Layer 0 — the actual YouTube iframe player (no native controls).
          iframe_pkg.YoutubePlayer(
            controller: _controller.iframeController,
            aspectRatio: _aspectRatio,
            // Disable iframe's OverlayPortal fullscreen so Flutter controls
            // stay correctly layered over the player at all times.
            autoFullScreen: false,
            enableFullScreenOnVerticalDrag: false,
          ),
          // Layer 1 — thumbnail fades out once playback begins.
          if (!_controller.flags.hideThumbnail)
            AnimatedOpacity(
              opacity: _controller.value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: widget.thumbnail ?? _defaultThumbnail,
            ),
          // Layer 2 — thin progress indicator below the player.
          if (!_controller.value.isFullScreen &&
              !_controller.flags.hideControls &&
              _controller.value.position > const Duration(milliseconds: 100) &&
              !_controller.value.isControlsVisible &&
              widget.showVideoProgressIndicator &&
              !_controller.flags.isLive)
            Positioned(
              bottom: -7.0,
              left: -7.0,
              right: -7.0,
              child: IgnorePointer(
                child: ProgressBar(
                  colors: widget.progressColors.copyWith(
                    handleColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          // Layers 3–6 — overlay controls.
          if (!_controller.flags.hideControls) ...[
            TouchShutter(
              disableDragSeek: _controller.flags.disableDragSeek,
              timeOut: widget.controlsTimeOut,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _controller.value.isControlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: _controller.flags.isLive
                    ? LiveBottomBar(
                        liveUIColor: widget.liveUIColor,
                        showLiveFullscreenButton:
                            _controller.flags.showLiveFullscreenButton,
                      )
                    : Padding(
                        padding: widget.bottomActions == null
                            ? EdgeInsets.zero
                            : widget.actionsPadding,
                        child: Row(
                          children: widget.bottomActions ??
                              [
                                const SizedBox(width: 14.0),
                                const CurrentPosition(),
                                const SizedBox(width: 8.0),
                                ProgressBar(
                                  isExpanded: true,
                                  colors: widget.progressColors,
                                ),
                                const RemainingDuration(),
                                const PlaybackSpeedButton(),
                                const FullScreenButton(),
                              ],
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _controller.value.isControlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: widget.actionsPadding,
                  child: Row(
                    children: widget.topActions ?? [const SizedBox.shrink()],
                  ),
                ),
              ),
            ),
            const Center(child: PlayPauseButton()),
          ],
          // Layer 7 — error overlay.
          if (_controller.value.hasError) errorWidget,
        ],
      ),
    );
  }

  Widget get _defaultThumbnail => Image.network(
        YoutubePlayer.getThumbnail(
          videoId: _controller.metadata.videoId.isEmpty
              ? _controller.initialVideoId
              : _controller.metadata.videoId,
        ),
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const ColoredBox(color: Colors.black),
        errorBuilder: (_, __, ___) => Image.network(
          YoutubePlayer.getThumbnail(
            videoId: _controller.metadata.videoId.isEmpty
                ? _controller.initialVideoId
                : _controller.metadata.videoId,
            webp: false,
          ),
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : const ColoredBox(color: Colors.black),
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
}
