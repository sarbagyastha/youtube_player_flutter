// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

PlatformWebViewControllerCreationParams buildWebViewParams({
  bool credentialless = false,
}) {
  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    return WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
  }
  return const PlatformWebViewControllerCreationParams();
}

void configureWebViewController(WebViewController controller) {
  final platform = controller.platform;
  if (platform is AndroidWebViewController) {
    AndroidWebViewController.enableDebugging(false);
    platform.setMediaPlaybackRequiresUserGesture(false);
  } else if (platform is WebKitWebViewController) {
    platform.setAllowsBackForwardNavigationGestures(false);
  }
}
