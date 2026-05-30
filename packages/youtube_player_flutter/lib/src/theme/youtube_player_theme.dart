// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A [ThemeExtension] that controls the visual appearance of [YoutubePlayer].
///
/// All properties are nullable — null means "inherit from the app's [ThemeData]"
/// (via [ColorScheme] tokens) with a hardcoded fallback as a last resort.
/// Only set values here when you need to override the Material 3 defaults.
///
/// ### App-level setup
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const [
///       YoutubePlayerTheme(progressBarActiveColor: Colors.red),
///     ],
///   ),
/// )
/// ```
@immutable
class YoutubePlayerTheme extends ThemeExtension<YoutubePlayerTheme> {
  const YoutubePlayerTheme({
    this.progressBarActiveColor,
    this.progressBarBufferedColor,
    this.progressBarBackgroundColor,
    this.controlsColor,
    this.controlsBackgroundGradient,
    this.titleStyle,
    this.timerStyle,
  });

  /// Color of the played portion of the seek bar.
  /// Defaults to [ColorScheme.primary].
  final Color? progressBarActiveColor;

  /// Color of the buffered portion of the seek bar.
  /// Defaults to [ColorScheme.primary] at 40% opacity.
  final Color? progressBarBufferedColor;

  /// Color of the unplayed portion of the seek bar track.
  /// Defaults to [Colors.white24].
  final Color? progressBarBackgroundColor;

  /// Color applied to all control icons and text.
  /// Defaults to [Colors.white].
  final Color? controlsColor;

  /// Gradient painted behind the top and bottom control bars.
  /// When null, a black-to-transparent gradient is used.
  final LinearGradient? controlsBackgroundGradient;

  /// Text style for the video title in the top bar.
  /// Defaults to [TextTheme.titleSmall] in white.
  final TextStyle? titleStyle;

  /// Text style for the elapsed/total time labels.
  /// Defaults to [TextTheme.labelMedium] in white.
  final TextStyle? timerStyle;

  @override
  YoutubePlayerTheme copyWith({
    Color? progressBarActiveColor,
    Color? progressBarBufferedColor,
    Color? progressBarBackgroundColor,
    Color? controlsColor,
    LinearGradient? controlsBackgroundGradient,
    TextStyle? titleStyle,
    TextStyle? timerStyle,
  }) {
    return YoutubePlayerTheme(
      progressBarActiveColor:
          progressBarActiveColor ?? this.progressBarActiveColor,
      progressBarBufferedColor:
          progressBarBufferedColor ?? this.progressBarBufferedColor,
      progressBarBackgroundColor:
          progressBarBackgroundColor ?? this.progressBarBackgroundColor,
      controlsColor: controlsColor ?? this.controlsColor,
      controlsBackgroundGradient:
          controlsBackgroundGradient ?? this.controlsBackgroundGradient,
      titleStyle: titleStyle ?? this.titleStyle,
      timerStyle: timerStyle ?? this.timerStyle,
    );
  }

  @override
  YoutubePlayerTheme lerp(YoutubePlayerTheme? other, double t) {
    if (other == null) return this;
    return YoutubePlayerTheme(
      progressBarActiveColor:
          Color.lerp(progressBarActiveColor, other.progressBarActiveColor, t),
      progressBarBufferedColor: Color.lerp(
        progressBarBufferedColor,
        other.progressBarBufferedColor,
        t,
      ),
      progressBarBackgroundColor: Color.lerp(
        progressBarBackgroundColor,
        other.progressBarBackgroundColor,
        t,
      ),
      controlsColor: Color.lerp(controlsColor, other.controlsColor, t),
      controlsBackgroundGradient: LinearGradient.lerp(
        controlsBackgroundGradient,
        other.controlsBackgroundGradient,
        t,
      ),
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t),
      timerStyle: TextStyle.lerp(timerStyle, other.timerStyle, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YoutubePlayerTheme &&
        other.progressBarActiveColor == progressBarActiveColor &&
        other.progressBarBufferedColor == progressBarBufferedColor &&
        other.progressBarBackgroundColor == progressBarBackgroundColor &&
        other.controlsColor == controlsColor &&
        other.controlsBackgroundGradient == controlsBackgroundGradient &&
        other.titleStyle == titleStyle &&
        other.timerStyle == timerStyle;
  }

  @override
  int get hashCode => Object.hash(
    progressBarActiveColor,
    progressBarBufferedColor,
    progressBarBackgroundColor,
    controlsColor,
    controlsBackgroundGradient,
    titleStyle,
    timerStyle,
  );
}

/// Resolves effective theme values by merging [YoutubePlayerTheme] extension
/// values with Material 3 [ColorScheme] tokens and hardcoded fallbacks.
class YoutubePlayerThemeResolver {
  YoutubePlayerThemeResolver(BuildContext context)
    : _ext = Theme.of(context).extension<YoutubePlayerTheme>(),
      _cs = Theme.of(context).colorScheme,
      _tt = Theme.of(context).textTheme;

  final YoutubePlayerTheme? _ext;
  final ColorScheme _cs;
  final TextTheme _tt;

  Color get progressBarActiveColor =>
      _ext?.progressBarActiveColor ?? _cs.primary;

  Color get progressBarBufferedColor =>
      _ext?.progressBarBufferedColor ?? _cs.primary.withValues(alpha: 0.4);

  Color get progressBarBackgroundColor =>
      _ext?.progressBarBackgroundColor ?? Colors.white24;

  Color get controlsColor => _ext?.controlsColor ?? Colors.white;

  LinearGradient get topGradient =>
      _ext?.controlsBackgroundGradient ??
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x99000000), Colors.transparent],
      );

  LinearGradient get bottomGradient =>
      _ext?.controlsBackgroundGradient ??
      const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0x99000000), Colors.transparent],
      );

  TextStyle get titleStyle =>
      _ext?.titleStyle ??
      (_tt.titleSmall ?? const TextStyle()).copyWith(color: Colors.white);

  TextStyle get timerStyle =>
      _ext?.timerStyle ??
      (_tt.labelMedium ?? const TextStyle()).copyWith(color: Colors.white70);
}
