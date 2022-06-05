import 'package:webview_flutter/webview_flutter.dart';

import '../overrides/webview_flutter_web.dart';

void registerWebViewWebImplementation() {
  WebView.platform = WebWebViewPlatform();
}
