import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:youtube_player/youtube_player.dart';

import '../data/videos.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/section_card.dart';

/// Every [YoutubePlayerParams] option. Params apply when the player is
/// created, so "Apply" creates a new controller.
class const ParamsPage({super.key}) extends StatefulWidget {
  @override
  State<ParamsPage> createState() => _ParamsPageState();
}

/// The editable options; defaults match [YoutubePlayerParams].
final class _Options {
  var mute = false;
  var showControls = true;
  var showFullscreenButton = true;
  var enableKeyboard = false;
  var enableCaption = true;
  var captionLanguage = 'en';
  var interfaceLanguage = 'en';
  var showVideoAnnotations = true;
  var strictRelatedVideos = false;
  var privacyEnhancedMode = true;
  var playsInline = true;
  var loop = false;
  var color = ProgressBarColor.white;
  var pointerEvents = PointerEvents.initial;
  var fullscreenOrientation = FullscreenOrientation.landscape;
  var videoStateUpdateInterval = 100;
  var aspectRatio = 16 / 9;
  var backgroundColor = const Color(0xFF000000);

  _Options copy() => _Options()
    ..mute = mute
    ..showControls = showControls
    ..showFullscreenButton = showFullscreenButton
    ..enableKeyboard = enableKeyboard
    ..enableCaption = enableCaption
    ..captionLanguage = captionLanguage
    ..interfaceLanguage = interfaceLanguage
    ..showVideoAnnotations = showVideoAnnotations
    ..strictRelatedVideos = strictRelatedVideos
    ..privacyEnhancedMode = privacyEnhancedMode
    ..playsInline = playsInline
    ..loop = loop
    ..color = color
    ..pointerEvents = pointerEvents
    ..fullscreenOrientation = fullscreenOrientation
    ..videoStateUpdateInterval = videoStateUpdateInterval
    ..aspectRatio = aspectRatio
    ..backgroundColor = backgroundColor;

  YoutubePlayerParams toParams() => YoutubePlayerParams(
    mute: mute,
    showControls: showControls,
    showFullscreenButton: showFullscreenButton,
    enableKeyboard: enableKeyboard,
    enableCaption: enableCaption,
    captionLanguage: captionLanguage,
    interfaceLanguage: interfaceLanguage,
    showVideoAnnotations: showVideoAnnotations,
    strictRelatedVideos: strictRelatedVideos,
    privacyEnhancedMode: privacyEnhancedMode,
    playsInline: playsInline,
    loop: loop,
    color: color,
    pointerEvents: pointerEvents,
    fullscreenOrientation: fullscreenOrientation,
    videoStateUpdateInterval: videoStateUpdateInterval,
  );

  /// Dart code for the options that differ from the defaults.
  String toCode() {
    final d = _Options();
    final args = [
      if (mute != d.mute) 'mute: $mute',
      if (showControls != d.showControls) 'showControls: $showControls',
      if (showFullscreenButton != d.showFullscreenButton)
        'showFullscreenButton: $showFullscreenButton',
      if (enableKeyboard != d.enableKeyboard) 'enableKeyboard: $enableKeyboard',
      if (enableCaption != d.enableCaption) 'enableCaption: $enableCaption',
      if (captionLanguage != d.captionLanguage)
        "captionLanguage: '$captionLanguage'",
      if (interfaceLanguage != d.interfaceLanguage)
        "interfaceLanguage: '$interfaceLanguage'",
      if (showVideoAnnotations != d.showVideoAnnotations)
        'showVideoAnnotations: $showVideoAnnotations',
      if (strictRelatedVideos != d.strictRelatedVideos)
        'strictRelatedVideos: $strictRelatedVideos',
      if (privacyEnhancedMode != d.privacyEnhancedMode)
        'privacyEnhancedMode: $privacyEnhancedMode',
      if (playsInline != d.playsInline) 'playsInline: $playsInline',
      if (loop != d.loop) 'loop: $loop',
      if (color != d.color) 'color: .${color.name}',
      if (pointerEvents != d.pointerEvents)
        'pointerEvents: .${pointerEvents.name}',
      if (fullscreenOrientation != d.fullscreenOrientation)
        'fullscreenOrientation: .${fullscreenOrientation.name}',
      if (videoStateUpdateInterval != d.videoStateUpdateInterval)
        'videoStateUpdateInterval: $videoStateUpdateInterval',
    ];
    final params = args.isEmpty
        ? 'const YoutubePlayerParams()'
        : 'const YoutubePlayerParams(\n${args.map((a) => '    $a,\n').join()}  )';
    final widget = [
      if (aspectRatio != d.aspectRatio)
        'aspectRatio: ${_ratios.entries.firstWhere((e) => e.value == aspectRatio).key.replaceAll(':', ' / ')}',
      if (backgroundColor != d.backgroundColor)
        'backgroundColor: Color(0x${backgroundColor.toARGB32().toRadixString(16).toUpperCase()})',
    ];
    return 'final controller = YoutubePlayerController.fromVideoId(\n'
        '  videoId: \'…\',\n'
        '  params: $params,\n'
        ');\n\n'
        'YoutubePlayer(\n'
        '  controller: controller,\n'
        '${widget.map((w) => '  $w,\n').join()}'
        ')';
  }
}

const _languages = {
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'ja': '日本語',
  'ne': 'नेपाली',
};

const _ratios = {'16:9': 16 / 9, '4:3': 4 / 3, '1:1': 1.0};

const _backgrounds = [
  Color(0xFF000000),
  Color(0xFF1E1E2E),
  Color(0xFF7F0000),
  Color(0xFF0D47A1),
];

class _ParamsPageState extends State<ParamsPage> {
  var _draft = _Options();
  var _applied = _Options();
  var _generation = 0;
  var _dirty = false;

  void _edit(void Function(_Options o) change) => setState(() {
    change(_draft);
    _dirty = true;
  });

  void _apply() => setState(() {
    _applied = _draft.copy();
    _generation++;
    _dirty = false;
  });

  void _reset() => setState(() {
    _draft = _Options();
    _dirty = true;
  });

  @override
  Widget build(BuildContext context) {
    final o = _draft;
    Widget toggle(
      String title,
      String subtitle,
      bool value,
      void Function(_Options o, bool v) set,
    ) => SwitchListTile(
      dense: true,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (v) => _edit((o) => set(o, v)),
    );

    final applied = _applied;
    return DemoScaffold(
      title: 'Player parameters',
      controllerKey: _generation,
      create: () => YoutubePlayerController.fromVideoId(
        videoId: videoIds[5],
        params: applied.toParams(),
      ),
      playerBuilder: (context, controller) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: YoutubePlayer(
            controller: controller,
            aspectRatio: applied.aspectRatio,
            backgroundColor: applied.backgroundColor,
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Reset to defaults',
          icon: const Icon(Icons.settings_backup_restore),
          onPressed: _reset,
        ),
      ],
      children: [
        _ApplyBar(dirty: _dirty, onApply: _apply),
        SectionCard(
          title: 'Controls',
          icon: Icons.gamepad_outlined,
          child: Column(
            children: [
              toggle(
                'Show controls',
                'controls',
                o.showControls,
                (o, v) => o.showControls = v,
              ),
              toggle(
                'Fullscreen button',
                'fs',
                o.showFullscreenButton,
                (o, v) => o.showFullscreenButton = v,
              ),
              toggle(
                'Keyboard shortcuts',
                'disablekb',
                o.enableKeyboard,
                (o, v) => o.enableKeyboard = v,
              ),
              _Labeled(
                'Progress bar color',
                SegmentedButton<ProgressBarColor>(
                  segments: const [
                    ButtonSegment(value: .red, label: Text('Red')),
                    ButtonSegment(value: .white, label: Text('White')),
                  ],
                  selected: {o.color},
                  onSelectionChanged: (s) => _edit((o) => o.color = s.single),
                ),
              ),
              _Labeled(
                'Pointer events',
                SegmentedButton<PointerEvents>(
                  segments: [
                    for (final p in PointerEvents.values)
                      ButtonSegment(value: p, label: Text(p.name)),
                  ],
                  selected: {o.pointerEvents},
                  onSelectionChanged: (s) =>
                      _edit((o) => o.pointerEvents = s.single),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Playback',
          icon: Icons.play_circle_outline,
          child: Column(
            children: [
              toggle('Start muted', 'mute', o.mute, (o, v) => o.mute = v),
              toggle('Loop playlists', 'loop', o.loop, (o, v) => o.loop = v),
              toggle(
                'Play inline (iOS)',
                'playsinline',
                o.playsInline,
                (o, v) => o.playsInline = v,
              ),
              _Labeled(
                'Position updates: ${o.videoStateUpdateInterval} ms',
                Slider(
                  value: o.videoStateUpdateInterval.toDouble(),
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  onChanged: (v) =>
                      _edit((o) => o.videoStateUpdateInterval = v.round()),
                ),
              ),
              _Labeled(
                'Fullscreen orientation (Android)',
                SegmentedButton<FullscreenOrientation>(
                  segments: [
                    for (final f in FullscreenOrientation.values)
                      ButtonSegment(value: f, label: Text(f.name)),
                  ],
                  selected: {o.fullscreenOrientation},
                  onSelectionChanged: (s) =>
                      _edit((o) => o.fullscreenOrientation = s.single),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Captions & language',
          icon: Icons.closed_caption_outlined,
          child: Column(
            children: [
              toggle(
                'Show captions',
                'cc_load_policy',
                o.enableCaption,
                (o, v) => o.enableCaption = v,
              ),
              _LanguagePicker(
                label: 'Caption language',
                value: o.captionLanguage,
                onChanged: (v) => _edit((o) => o.captionLanguage = v),
              ),
              _LanguagePicker(
                label: 'Interface language',
                value: o.interfaceLanguage,
                onChanged: (v) => _edit((o) => o.interfaceLanguage = v),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Content & privacy',
          icon: Icons.privacy_tip_outlined,
          child: Column(
            children: [
              toggle(
                'Annotations',
                'iv_load_policy',
                o.showVideoAnnotations,
                (o, v) => o.showVideoAnnotations = v,
              ),
              toggle(
                'Related from same channel',
                'rel=0',
                o.strictRelatedVideos,
                (o, v) => o.strictRelatedVideos = v,
              ),
              toggle(
                'Privacy-enhanced mode',
                'youtube-nocookie.com',
                o.privacyEnhancedMode,
                (o, v) => o.privacyEnhancedMode = v,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Widget',
          icon: Icons.aspect_ratio,
          child: Column(
            children: [
              _Labeled(
                'Aspect ratio',
                SegmentedButton<double>(
                  segments: [
                    for (final MapEntry(:key, :value) in _ratios.entries)
                      ButtonSegment(value: value, label: Text(key)),
                  ],
                  selected: {o.aspectRatio},
                  onSelectionChanged: (s) =>
                      _edit((o) => o.aspectRatio = s.single),
                ),
              ),
              _Labeled(
                'Background color',
                Wrap(
                  spacing: 8,
                  children: [
                    for (final color in _backgrounds)
                      ChoiceChip(
                        label: const SizedBox(width: 16, height: 16),
                        avatar: CircleAvatar(backgroundColor: color),
                        selected: o.backgroundColor == color,
                        onSelected: (_) =>
                            _edit((o) => o.backgroundColor = color),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Code',
          icon: Icons.code,
          trailing: IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: o.toCode()));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Copied')));
            },
          ),
          child: _CodeBlock(o.toCode()),
        ),
      ],
    );
  }
}

class const _ApplyBar({
  required final bool dirty,
  required final VoidCallback onApply,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const .fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: dirty ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: .circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dirty
                  ? 'Changes apply when the player is recreated.'
                  : 'Params are fixed when the player is created.',
            ),
          ),
          FilledButton.icon(
            onPressed: dirty ? onApply : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class const _Labeled(final String label, final Widget child)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: .start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: .horizontal, child: child),
      ],
    ),
  );
}

class const _LanguagePicker({
  required final String label,
  required final String value,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(vertical: 6),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        for (final MapEntry(:key, :value) in _languages.entries)
          DropdownMenuItem(value: key, child: Text('$value ($key)')),
      ],
      onChanged: (v) => onChanged(v!),
    ),
  );
}

class const _CodeBlock(final String code) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: .circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: .horizontal,
        child: SelectableText(
          code,
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
