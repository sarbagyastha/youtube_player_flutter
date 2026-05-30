// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../controller/overlay_controller_scope.dart';

/// Centered circular buttons: [previous |] play-pause [| next].
/// Skip buttons are only shown when a previous/next video is available.
class PlaybackControls extends StatefulWidget {
  const PlaybackControls({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls> {
  int _playlistIndex = 0;
  int _playlistSize = 0;
  String _lastVideoId = '';
  StreamSubscription<YoutubePlayerValue>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.controller.listen((value) {
      final videoId = value.metaData.videoId;
      if (videoId != _lastVideoId) {
        _lastVideoId = videoId;
        _refreshPlaylistInfo();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _refreshPlaylistInfo() async {
    try {
      final results = await Future.wait([
        widget.controller.playlist,
        widget.controller.playlistIndex,
      ]);
      if (!mounted) return;
      setState(() {
        _playlistSize = (results[0] as List).length;
        _playlistIndex = results[1] as int;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _playlistSize = 0;
        _playlistIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPrevious = _playlistIndex > 0;
    final hasNext = _playlistSize > 1 && _playlistIndex < _playlistSize - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPrevious) ...[
          _CircleButton(
            icon: Icons.skip_previous_rounded,
            onTap: () {
              widget.controller.previousVideo();
              OverlayControllerScope.of(context).resetTimer();
            },
          ),
          const SizedBox(width: 16),
        ],
        YoutubeValueBuilder(
          controller: widget.controller,
          buildWhen: (o, n) => o.playerState != n.playerState,
          builder: (context, value) {
            final isPlaying = value.playerState == PlayerState.playing;
            return _AnimatedPlayPauseButton(
              isPlaying: isPlaying,
              onTap: () {
                isPlaying
                    ? widget.controller.pauseVideo()
                    : widget.controller.playVideo();
                OverlayControllerScope.of(context).resetTimer();
              },
            );
          },
        ),
        if (hasNext) ...[
          const SizedBox(width: 16),
          _CircleButton(
            icon: Icons.skip_next_rounded,
            onTap: () {
              widget.controller.nextVideo();
              OverlayControllerScope.of(context).resetTimer();
            },
          ),
        ],
      ],
    );
  }
}

class _AnimatedPlayPauseButton extends StatefulWidget {
  const _AnimatedPlayPauseButton({
    required this.isPlaying,
    required this.onTap,
  });

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  State<_AnimatedPlayPauseButton> createState() =>
      _AnimatedPlayPauseButtonState();
}

class _AnimatedPlayPauseButtonState extends State<_AnimatedPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isPlaying ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(_AnimatedPlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      widget.isPlaying ? _animController.forward() : _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: Center(
          child: SizedBox.square(
            dimension: 56,
            child: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _animController,
              color: Colors.white,
              size: 54,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
