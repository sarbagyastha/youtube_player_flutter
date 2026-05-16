import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

PlatformWebViewControllerCreationParams buildWebViewParams() {
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
