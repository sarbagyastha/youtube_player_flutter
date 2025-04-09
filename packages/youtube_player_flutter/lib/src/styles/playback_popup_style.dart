import 'package:flutter/widgets.dart';

class PlaybackPopupStyle {
  final Color? backgroundColor;
  final ShapeBorder? shape;
  final TextStyle? textStyle;
  final Color? iconColor;

  ///Default is const EdgeInsets.all(8.0)
  final EdgeInsetsGeometry? padding;

  /// Defrault is Offset.zero
  final Offset offset;
  final double? elevation;

  const PlaybackPopupStyle({
    this.backgroundColor,
    this.shape,
    this.textStyle,
    this.iconColor,
    this.padding,
    this.offset = Offset.zero,
    this.elevation,
  });
}
