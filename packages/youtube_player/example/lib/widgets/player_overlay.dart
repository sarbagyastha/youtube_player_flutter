import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../utils/format.dart';

/// Flutter controls drawn over the player via `YoutubePlayer.controlsBuilder`.
///
/// Tap shows or hides them (they hide by themselves while playing),
/// double-tap the left or right half to skip 10 seconds.
class const PlayerOverlay(final YoutubePlayerValue value, {super.key})
    extends StatefulWidget {
  @override
  State<PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends State<PlayerOverlay> {
  var _visible = true;
  Timer? _hideTimer;
  double? _drag;

  /// Feedback after a double-tap skip: `-1` left, `1` right.
  int _skipSide = 0;
  Timer? _skipTimer;
  Offset _tapPosition = .zero;

  bool get _playing => widget.value.playerState.isActive;

  @override
  void didUpdateWidget(PlayerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.playerState != widget.value.playerState) {
      _scheduleHide();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_playing) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _show() {
    setState(() => _visible = true);
    _scheduleHide();
  }

  void _skip(double width) {
    final side = _tapPosition.dx < width / 2 ? -1 : 1;
    final controller = context.ytController;
    controller.seekTo(
      seconds: math.max(0, controller.currentTime + 10 * side),
      allowSeekAhead: true,
    );
    _skipTimer?.cancel();
    setState(() => _skipSide = side);
    _skipTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _skipSide = 0);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _skipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    final value = widget.value;
    final shown = _visible || !_playing;
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: .opaque,
        onTap: () =>
            shown && _playing ? setState(() => _visible = false) : _show(),
        onDoubleTapDown: (d) => _tapPosition = d.localPosition,
        onDoubleTap: () => _skip(constraints.maxWidth),
        child: Stack(
          fit: .expand,
          children: [
            if (_skipSide != 0)
              Align(
                alignment: _skipSide < 0 ? .centerLeft : .centerRight,
                child: Padding(
                  padding: const .symmetric(horizontal: 32),
                  child: _Round(
                    child: Text(
                      _skipSide < 0 ? '−10 s' : '+10 s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: .w600,
                      ),
                    ),
                  ),
                ),
              ),
            IgnorePointer(
              ignoring: !shown,
              child: AnimatedOpacity(
                opacity: shown ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: _Controls(
                  value: value,
                  drag: _drag,
                  onDrag: (v) {
                    _hideTimer?.cancel();
                    setState(() => _drag = v);
                    controller.seekTo(seconds: v * controller.duration);
                  },
                  onDragEnd: (v) {
                    controller.seekTo(
                      seconds: v * controller.duration,
                      allowSeekAhead: true,
                    );
                    setState(() => _drag = null);
                    _scheduleHide();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _Controls({
  required final YoutubePlayerValue value,
  required final double? drag,
  required final ValueChanged<double> onDrag,
  required final ValueChanged<double> onDragEnd,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.ytController;
    final playing = value.playerState.isActive;
    const white = Colors.white;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: .topCenter,
          end: .bottomCenter,
          colors: [Color(0x99000000), Color(0x00000000), Color(0xB3000000)],
          stops: [0, .45, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Text(
              value.metaData.title,
              maxLines: 1,
              overflow: .ellipsis,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: white),
            ),
          ),
          Center(
            child: value.playerState == .buffering
                ? const SizedBox.square(
                    dimension: 56,
                    child: CircularProgressIndicator(color: white),
                  )
                : _Round(
                    onTap: playing
                        ? controller.pauseVideo
                        : controller.playVideo,
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 44,
                      color: white,
                    ),
                  ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 0,
            child: StreamBuilder<YoutubeVideoState>(
              stream: controller.videoStateStream,
              builder: (context, snapshot) {
                final total = value.metaData.duration.inMilliseconds;
                final position =
                    snapshot.data?.position ??
                    secondsToDuration(controller.currentTime);
                final fraction =
                    drag ??
                    (total == 0
                        ? 0.0
                        : (position.inMilliseconds / total).clamp(0.0, 1.0));
                const style = TextStyle(
                  color: white,
                  fontSize: 12,
                  fontFeatures: [.tabularFigures()],
                );
                return Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      formatDuration(
                        Duration(milliseconds: (fraction * total).round()),
                      ),
                      style: style,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          activeTrackColor: const Color(0xFFFF0000),
                          inactiveTrackColor: white.withValues(alpha: .3),
                          secondaryActiveTrackColor: white.withValues(
                            alpha: .6,
                          ),
                          thumbColor: const Color(0xFFFF0000),
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Padding(
                          padding: const .symmetric(horizontal: 12),
                          child: Slider(
                            value: fraction,
                            secondaryTrackValue:
                                (snapshot.data?.loadedFraction ??
                                        controller.videoLoadedFraction)
                                    .clamp(0, 1),
                            onChanged: total == 0 ? null : onDrag,
                            onChangeEnd: total == 0 ? null : onDragEnd,
                          ),
                        ),
                      ),
                    ),
                    Text(formatDuration(value.metaData.duration), style: style),
                    IconButton(
                      color: white,
                      tooltip: value.isMuted ? 'Unmute' : 'Mute',
                      icon: Icon(
                        value.isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                      ),
                      onPressed: value.isMuted
                          ? controller.unMute
                          : controller.mute,
                    ),
                    IconButton(
                      color: white,
                      tooltip: 'Fullscreen',
                      icon: const Icon(Icons.fullscreen_rounded),
                      onPressed: () async {
                        final accepted = await controller.enterFullScreen();
                        if (!accepted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fullscreen from Flutter is not allowed here.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class const _Round({required final Widget child, final VoidCallback? onTap})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x80000000),
    shape: const StadiumBorder(),
    clipBehavior: .antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: const .all(14), child: child),
    ),
  );
}
