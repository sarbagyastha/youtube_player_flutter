import 'package:flutter/material.dart';

/// Clip widget in oval shape at right side
class OvalRightBorderClipper extends CustomClipper<Path> {

  /// Create [OvalRightBorderClipper] widget
  const OvalRightBorderClipper({
    required this.curveHeight,
  });

  /// height of widget
  final double curveHeight;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, 0)
      ..lineTo(size.width - curveHeight, 0)
      ..quadraticBezierTo(
          size.width, size.height / 4, size.width, size.height / 2)
      ..quadraticBezierTo(size.width, size.height - (size.height / 4),
          size.width - curveHeight, size.height)
      ..lineTo(0, size.height);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
