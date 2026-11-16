import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/videos.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/section_card.dart';
import '../widgets/seek_bar.dart';
import '../widgets/transport_controls.dart';
import '../widgets/video_header.dart';

/// A 360° video steered from Flutter with `setSphericalProperties`.
class const SphericalPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: '360° video',
    create: () => YoutubePlayerController.fromVideoId(
      videoId: sphericalVideoId,
      autoPlay: true,
      params: const YoutubePlayerParams(mute: true),
    ),
    children: const [
      VideoHeader(),
      SectionCard(
        title: 'Camera',
        icon: Icons.threesixty,
        note:
            'Drag the pad or use the sliders. Values are read back with '
            'sphericalProperties. YouTube supports 360° on Android and in '
            'Chromium browsers; Safari / WebKit (iOS, macOS) plays it flat.',
        child: _SphericalControls(),
      ),
      SectionCard(
        title: 'Playback',
        icon: Icons.smart_display_outlined,
        child: Column(children: [SeekBar(), TransportControls()]),
      ),
    ],
  );
}

class const _SphericalControls() extends StatefulWidget {
  @override
  State<_SphericalControls> createState() => _SphericalControlsState();
}

class _SphericalControlsState extends State<_SphericalControls> {
  static const _home = (yaw: 0.0, pitch: 0.0, roll: 0.0, fov: 100.0);

  var _view = _home;
  var _sensor = false;

  /// Whether the player reported spherical properties yet.
  var _isSpherical = false;

  /// Empty reads while playing; after a few, the platform has no 360° mode.
  var _emptyReads = 0;
  Timer? _poll;

  /// Polling is paused briefly after the user moves the camera, so stale
  /// values don't fight the gesture.
  DateTime _pauseUntil = DateTime(0);

  /// The video plays, but this platform has no 360° mode.
  bool get _flat => _emptyReads >= 6;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(milliseconds: 500), (_) => _read());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _read() async {
    if (DateTime.now().isBefore(_pauseUntil)) return;
    final props = await context.ytController.sphericalProperties;
    if (!mounted || DateTime.now().isBefore(_pauseUntil)) return;
    if (props.isEmpty) {
      final playing = context.ytController.playerState == .playing;
      setState(() {
        _isSpherical = false;
        if (playing) _emptyReads++;
      });
      return;
    }
    setState(() {
      _isSpherical = true;
      _emptyReads = 0;
      _view = (
        yaw: props.yaw ?? _view.yaw,
        pitch: props.pitch ?? _view.pitch,
        roll: props.roll ?? _view.roll,
        fov: props.fov ?? _view.fov,
      );
    });
  }

  void _set({double? yaw, double? pitch, double? roll, double? fov}) {
    _pauseUntil = DateTime.now().add(const Duration(seconds: 1));
    setState(() {
      _view = (
        yaw: (yaw ?? _view.yaw) % 360,
        pitch: (pitch ?? _view.pitch).clamp(-90.0, 90.0),
        roll: (roll ?? _view.roll).clamp(-180.0, 180.0),
        fov: (fov ?? _view.fov).clamp(30.0, 120.0),
      );
    });
    context.ytController.setSphericalProperties(
      SphericalProperties(
        yaw: _view.yaw,
        pitch: _view.pitch,
        roll: _view.roll,
        fov: _view.fov,
        enableOrientationSensor: _sensor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (!_isSpherical)
          Padding(
            padding: const .only(bottom: 12),
            child: Row(
              children: [
                if (_flat)
                  Icon(
                    Icons.panorama_horizontal,
                    size: 16,
                    color: theme.colorScheme.error,
                  )
                else
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _flat
                        ? 'No 360° mode here: the player reports no '
                              'spherical properties, so it plays flat.'
                        : 'Waiting for a playing 360° video…',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        _LookPad(
          yaw: _view.yaw,
          pitch: _view.pitch,
          onPan: (delta) => _set(
            yaw: _view.yaw - delta.dx * 0.4,
            pitch: _view.pitch + delta.dy * 0.4,
          ),
        ),
        const SizedBox(height: 12),
        _AngleSlider(
          label: 'Yaw',
          value: _view.yaw,
          min: 0,
          max: 359.9,
          onChanged: (v) => _set(yaw: v),
        ),
        _AngleSlider(
          label: 'Pitch',
          value: _view.pitch,
          min: -90,
          max: 90,
          onChanged: (v) => _set(pitch: v),
        ),
        _AngleSlider(
          label: 'Roll',
          value: _view.roll,
          min: -180,
          max: 180,
          onChanged: (v) => _set(roll: v),
        ),
        _AngleSlider(
          label: 'Zoom (FOV)',
          value: _view.fov,
          min: 30,
          max: 120,
          onChanged: (v) => _set(fov: v),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, yaw, pitch) in [
              ('Front', 0.0, 0.0),
              ('Right', 90.0, 0.0),
              ('Back', 180.0, 0.0),
              ('Left', 270.0, 0.0),
              ('Up', _view.yaw, 60.0),
              ('Down', _view.yaw, -60.0),
            ])
              ActionChip(
                label: Text(label),
                onPressed: () => _set(yaw: yaw, pitch: pitch),
              ),
            ActionChip(
              avatar: const Icon(Icons.center_focus_strong),
              label: const Text('Reset'),
              onPressed: () => _set(
                yaw: _home.yaw,
                pitch: _home.pitch,
                roll: _home.roll,
                fov: _home.fov,
              ),
            ),
          ],
        ),
        SwitchListTile(
          title: const Text('Use device motion'),
          subtitle: const Text('enableOrientationSensor, on supported phones'),
          value: _sensor,
          onChanged: (on) {
            setState(() => _sensor = on);
            _set();
          },
        ),
      ],
    );
  }
}

/// A drag pad mapping yaw to x and pitch to y, with a marker for the view.
class const _LookPad({
  required final double yaw,
  required final double pitch,
  required final ValueChanged<Offset> onPan,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onPanUpdate: (d) => onPan(d.delta),
      child: AspectRatio(
        aspectRatio: 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: .circular(16),
            gradient: LinearGradient(
              begin: .topCenter,
              end: .bottomCenter,
              colors: [scheme.primaryContainer, scheme.tertiaryContainer],
            ),
          ),
          child: CustomPaint(
            painter: _LookPainter(
              yaw: yaw,
              pitch: pitch,
              grid: scheme.onPrimaryContainer.withValues(alpha: .2),
              marker: scheme.primary,
            ),
            child: Center(
              child: Text(
                'Drag to look around',
                style: TextStyle(
                  color: scheme.onPrimaryContainer.withValues(alpha: .6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LookPainter extends CustomPainter {
  _LookPainter({
    required this.yaw,
    required this.pitch,
    required this.grid,
    required this.marker,
  });

  final double yaw;
  final double pitch;
  final Color grid;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    // Meridians every 45°, parallels every 30°.
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final center = Offset(
      size.width * yaw / 360,
      size.height * (90 - pitch) / 180,
    );
    canvas
      ..drawCircle(center, 16, Paint()..color = marker.withValues(alpha: .25))
      ..drawCircle(center, 7, Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_LookPainter old) =>
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.grid != grid ||
      old.marker != marker;
}

class const _AngleSlider({
  required final String label,
  required final double value,
  required final double min,
  required final double max,
  required final ValueChanged<double> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 88, child: Text(label)),
      Expanded(
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ),
      SizedBox(
        width: 48,
        child: Text(
          '${value.round()}°',
          textAlign: .end,
          style: const TextStyle(fontFeatures: [.tabularFigures()]),
        ),
      ),
    ],
  );
}
