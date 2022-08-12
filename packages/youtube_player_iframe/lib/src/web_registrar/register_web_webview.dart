import 'package:webview_flutter/webview_flutter.dart';

import '../overrides/webview_flutter_web.dart';

/// Registers the web implementation for the youtube player.
void registerWebViewWebImplementation() {
  WebView.platform = WebWebViewPlatform();
}
