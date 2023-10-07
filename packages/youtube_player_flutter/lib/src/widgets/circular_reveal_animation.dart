import 'package:flutter/material.dart';
import 'circular_reveal_clipper.dart';

/// circle widget
class CircularRevealAnimation extends StatelessWidget {

  /// [centerAlignment] center of circular reveal. [centerOffset] if not specified.
  final Alignment? centerAlignment;
  /// [centerOffset] center of circular reveal. Child's center if not specified.
  final Offset? centerOffset;
  /// [minRadius] minimum radius of circular reveal. 0 if not if not specified.
  final double? minRadius;
  /// [maxRadius] maximum radius of circular reveal. Distance from center to further child's corner if not specified.
  final double? maxRadius;
  /// [child] child will show of class.
  final Widget child;
  /// For open animation [animation] should run forward: [AnimationController.forward].
  /// For close animation [animation] should run reverse: [AnimationController.reverse].
  final Animation<double> animation;

  /// Creates [CircularRevealAnimation] with given params.
  /// [centerAlignment] or [centerOffset] must be null (or both).
  CircularRevealAnimation({
    required this.child,
    required this.animation,
    this.centerAlignment,
    this.centerOffset,
    this.minRadius,
    this.maxRadius,
  }) : assert(centerAlignment == null || centerOffset == null);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return ClipPath(
          clipper: CircularRevealClipper(
            fraction: animation.value,
            centerAlignment: centerAlignment,
            centerOffset: centerOffset,
            minRadius: minRadius,
            maxRadius: maxRadius,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}
