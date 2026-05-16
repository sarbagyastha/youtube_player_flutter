import 'package:flutter/foundation.dart';

/// True when running on Android or iOS.
///
/// Web and macOS delegate fullscreen and background-color handling to the
/// system / browser, so they are excluded from mobile-specific logic.
final bool isMobile =
    !kIsWeb && defaultTargetPlatform != TargetPlatform.macOS;
