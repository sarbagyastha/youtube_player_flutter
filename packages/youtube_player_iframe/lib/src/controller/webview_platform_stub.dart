// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe_web/youtube_player_iframe_web.dart';

PlatformWebViewControllerCreationParams buildWebViewParams({
  bool credentialless = false,
}) {
  return WebYoutubePlayerIframeControllerCreationParams(
    credentialless: credentialless,
  );
}

void configureWebViewController(WebViewController controller) {}
