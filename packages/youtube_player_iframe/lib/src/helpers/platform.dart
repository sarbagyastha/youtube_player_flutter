// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// True when running on Android or iOS.
///
/// Web and desktop platforms (macOS, Windows, Linux) delegate fullscreen and
/// background-color handling to the system / browser, so they are excluded
/// from mobile-specific logic.
final bool isMobile =
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
