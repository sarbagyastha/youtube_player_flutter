import 'package:flutter/material.dart';

/// Clip widget in oval shape at right side
class OvalLeftBorderClipper extends CustomClipper<Path> {

  /// Create [OvalLeftBorderClipper] widget
  OvalLeftBorderClipper({
    required this.curveHeight,
  });

  /// height of widget
  final double curveHeight;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, 0)
      ..lineTo(curveHeight, 0)
      ..quadraticBezierTo(0, size.height / 4, 0, size.height / 2)
      ..quadraticBezierTo(
        0, size.height - (size.height / 4), curveHeight, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
