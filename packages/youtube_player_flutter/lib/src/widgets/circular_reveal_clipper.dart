import 'dart:math' show sqrt, max;

import 'package:flutter/material.dart';

/// A custom clipper for creating circular reveal animations.
///
/// The [CircularRevealClipper] is used with the [ClipPath] widget to create
/// circular reveal animations. It clips a portion of the widget with a circular
/// shape that can expand or contract based on the [fraction] property. You can
/// customize the center, minimum radius, and maximum radius of the reveal.
@immutable
class CircularRevealClipper extends CustomClipper<Path> {

  /// The fraction of the reveal animation.
  ///
  /// A value of 0.0 corresponds to no reveal (fully clipped), while 1.0
  /// corresponds to full reveal (no clipping).
  final double fraction;

  /// The alignment of the reveal center.
  ///
  /// If provided, this will be used to calculate the reveal center based on
  /// the size of the widget.
  final Alignment? centerAlignment;

  /// The offset of the reveal center.
  ///
  /// If provided, this will be used as the explicit center for the reveal.
  final Offset? centerOffset;

  /// The minimum radius of the circular reveal.
  final double? minRadius;

  /// The maximum radius of the circular reveal.
  final double? maxRadius;

  /// Create [CircularRevealClipper] widget
  CircularRevealClipper({
    required this.fraction,
    this.centerAlignment,
    this.centerOffset,
    this.minRadius,
    this.maxRadius,
  });

  @override
  Path getClip(Size size) {
    final center = centerAlignment?.alongSize(size) ??
        centerOffset ??
        Offset(size.width / 2, size.height / 2);
    final minRadius = this.minRadius ?? 0;
    final maxRadius = this.maxRadius ?? calcMaxRadius(size, center);

    return Path()
      ..addOval(
        Rect.fromCircle(
          center: center,
          radius: lerpDouble(minRadius, maxRadius, fraction),
        ),
      );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;

  /// Calculate the maximum radius of the circular reveal based on the size
  /// of the widget and the center point.
  static double calcMaxRadius(Size size, Offset center) {
    final w = max(center.dx, size.width - center.dx);
    final h = max(center.dy, size.height - center.dy);
    return sqrt(w * w + h * h);
  }

  /// Linear interpolation between two double values.
  static double lerpDouble(double a, double b, double t) {
    return a * (1.0 - t) + b * t;
  }
}
