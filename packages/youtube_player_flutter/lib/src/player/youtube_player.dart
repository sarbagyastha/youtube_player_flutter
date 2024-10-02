// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../enums/thumbnail_quality.dart';
import '../utils/errors.dart';
import '../utils/youtube_meta_data.dart';
import '../utils/youtube_player_controller.dart';
import '../utils/youtube_player_flags.dart';
import '../widgets/widgets.dart';
import 'raw_youtube_player.dart';

/// A widget to play or stream YouTube videos using the official [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference).
///
/// In order to play live videos, set `isLive` property to true in [YoutubePlayerFlags].
///
///
/// Using YoutubePlayer widget:
///
/// ```dart
/// YoutubePlayer(
///    context: context,
///    initialVideoId: "iLnmTe5Q2Qw",
///    flags: YoutubePlayerFlags(
///      autoPlay: true,
///      showVideoProgressIndicator: true,
///    ),
///    videoProgressIndicatorColor: Colors.amber,
///    progressColors: ProgressColors(
///      playedColor: Colors.amber,
///      handleColor: Colors.amberAccent,
///    ),
///    onPlayerInitialized: (controller) {
///      _controller = controller..addListener(listener);
///    },
///)
/// ```
///
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

  /// A [YoutubePlayerController] to control the player.
  final YoutubePlayerController controller;

  /// {@template youtube_player_flutter.width}
  /// Defines the width of the player.
  ///
  /// Default is devices's width.
  /// {@endtemplate}
  final double? width;

  /// {@template youtube_player_flutter.aspectRatio}
  /// Defines the aspect ratio to be assigned to the player. This property along with [width] calculates the player size.
  ///
  /// Default is 16 / 9.
  /// {@endtemplate}
  final double aspectRatio;

  /// {@template youtube_player_flutter.controlsTimeOut}
  /// The duration for which controls in the player will be visible.
  ///
  /// Default is 3 seconds.
  /// {@endtemplate}
  final Duration controlsTimeOut;

  /// {@template youtube_player_flutter.bufferIndicator}
  /// Overrides the default buffering indicator for the player.
  /// {@endtemplate}
  final Widget? bufferIndicator;

  /// {@template youtube_player_flutter.progressColors}
  /// Overrides default colors of the progress bar, takes [ProgressColors].
  /// {@endtemplate}
  final ProgressBarColors progressColors;

  /// {@template youtube_player_flutter.progressIndicatorColor}
  /// Overrides default color of progress indicator shown below the player(if enabled).
  /// {@endtemplate}
  final Color progressIndicatorColor;

  /// {@template youtube_player_flutter.onReady}
  /// Called when player is ready to perform control methods like:
  /// play(), pause(), load(), cue(), etc.
  /// {@endtemplate}
  final VoidCallback? onReady;

  /// {@template youtube_player_flutter.onEnded}
  /// Called when player had ended playing a video.
  ///
  /// Returns [YoutubeMetaData] for the video that has just ended playing.
  /// {@endtemplate}
  final void Function(YoutubeMetaData metaData)? onEnded;

  /// {@template youtube_player_flutter.liveUIColor}
  /// Overrides color of Live UI when enabled.
  /// {@endtemplate}
  final Color liveUIColor;

  /// {@template youtube_player_flutter.topActions}
  /// Adds custom top bar widgets.
  /// {@endtemplate}
  final List<Widget>? topActions;

  /// {@template youtube_player_flutter.bottomActions}
  /// Adds custom bottom bar widgets.
  /// {@endtemplate}
  final List<Widget>? bottomActions;

  /// {@template youtube_player_flutter.actionsPadding}
  /// Defines padding for [topActions] and [bottomActions].
  ///
  /// Default is EdgeInsets.all(8.0).
  /// {@endtemplate}
  final EdgeInsetsGeometry actionsPadding;

  /// {@template youtube_player_flutter.thumbnail}
  /// Thumbnail to show when player is loading.
  ///
  /// If not set, default thumbnail of the video is shown.
  /// {@endtemplate}
  final Widget? thumbnail;

  /// {@template youtube_player_flutter.showVideoProgressIndicator}
  /// Defines whether to show or hide progress indicator below the player.
  ///
  /// Default is false.
  /// {@endtemplate}
  final bool showVideoProgressIndicator;

  /// Converts fully qualified YouTube Url to video id.
  ///
  /// If videoId is passed as url then no conversion is done.
  static String? convertUrlToId(String url, {bool trimWhitespaces = true}) {
    if (!url.contains("http") && (url.length == 11)) return url;
    if (trimWhitespaces) url = url.trim();

    for (var exp in [
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(
          r"^https:\/\/(?:music\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube\.com\/shorts\/([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$")
    ]) {
      Match? match = exp.firstMatch(url);
      if (match != null && match.groupCount >= 1) return match.group(1);
    }

    return null;
  }

  /// Grabs YouTube video's thumbnail for provided video id.
  static String getThumbnail({
    required String videoId,
    String quality = ThumbnailQuality.standard,
    bool webp = true,
  }) =>
      webp
          ? 'https://i3.ytimg.com/vi_webp/$videoId/$quality.webp'
          : 'https://i3.ytimg.com/vi/$videoId/$quality.jpg';

  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer> {
  late YoutubePlayerController controller;

  late double _aspectRatio;
  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    controller = widget.controller..addListener(listener);
    _aspectRatio = widget.aspectRatio;
  }

  @override
  void didUpdateWidget(YoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(listener);
    widget.controller.addListener(listener);
  }

  void listener() async {
    if (controller.value.isReady && _initialLoad) {
      _initialLoad = false;
      if (controller.flags.autoPlay) controller.play();
      if (controller.flags.mute) controller.mute();
      widget.onReady?.call();
      if (controller.flags.controlsVisibleAtStart) {
        controller.updateValue(
          controller.value.copyWith(isControlsVisible: true),
        );
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.black,
      child: InheritedYoutubePlayer(
        controller: controller,
        child: Container(
          color: Colors.black,
          width: widget.width ?? MediaQuery.of(context).size.width,
          child: _buildPlayer(
            errorWidget: Container(
              color: Colors.black87,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5.0),
                      Expanded(
                        child: Text(
                          errorString(
                            controller.value.errorCode,
                            videoId: controller.metadata.videoId.isNotEmpty
                                ? controller.metadata.videoId
                                : controller.initialVideoId,
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
                    'Error Code: ${controller.value.errorCode}',
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
          RawYoutubePlayer(
            key: widget.key,
            onEnded: (YoutubeMetaData metaData) {
              if (controller.flags.loop) {
                controller.load(controller.metadata.videoId,
                    startAt: controller.flags.startAt,
                    endAt: controller.flags.endAt);
              }

              widget.onEnded?.call(metaData);
            },
          ),
          if (!controller.flags.hideThumbnail)
            AnimatedOpacity(
              opacity: controller.value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: widget.thumbnail ?? _thumbnail,
            ),
          if (!controller.value.isFullScreen &&
              !controller.flags.hideControls &&
              controller.value.position > const Duration(milliseconds: 100) &&
              !controller.value.isControlsVisible &&
              widget.showVideoProgressIndicator &&
              !controller.flags.isLive)
            Positioned(
              bottom: -7.0,
              left: -7.0,
              right: -7.0,
              child: IgnorePointer(
                ignoring: true,
                child: ProgressBar(
                  colors: widget.progressColors.copyWith(
                    handleColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          if (!controller.flags.hideControls) ...[
            TouchShutter(
              disableDragSeek: controller.flags.disableDragSeek,
              timeOut: widget.controlsTimeOut,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: !controller.flags.hideControls &&
                        controller.value.isControlsVisible
                    ? 1
                    : 0,
                duration: const Duration(milliseconds: 300),
                child: controller.flags.isLive
                    ? LiveBottomBar(
                        liveUIColor: widget.liveUIColor,
                        showLiveFullscreenButton:
                            widget.controller.flags.showLiveFullscreenButton,
                      )
                    : Padding(
                        padding: widget.bottomActions == null
                            ? const EdgeInsets.all(0.0)
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
                opacity: !controller.flags.hideControls &&
                        controller.value.isControlsVisible
                    ? 1
                    : 0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: widget.actionsPadding,
                  child: Row(
                    children: widget.topActions ?? [Container()],
                  ),
                ),
              ),
            ),
          ],
          if (!controller.flags.hideControls)
            const Center(child: PlayPauseButton()),
          if (controller.value.hasError) errorWidget,
        ],
      ),
    );
  }

  Widget get _thumbnail => Image.network(
        YoutubePlayer.getThumbnail(
          videoId: controller.metadata.videoId.isEmpty
              ? controller.initialVideoId
              : controller.metadata.videoId,
        ),
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : Container(color: Colors.black),
        errorBuilder: (context, _, __) => Image.network(
          YoutubePlayer.getThumbnail(
            videoId: controller.metadata.videoId.isEmpty
                ? controller.initialVideoId
                : controller.metadata.videoId,
            webp: false,
          ),
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : Container(color: Colors.black),
          errorBuilder: (context, _, __) => Container(),
        ),
      );
}
