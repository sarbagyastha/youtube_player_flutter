import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe_web/src/web_youtube_player_iframe_platform.dart';

/// Registers the web implementation for the youtube player.
void registerYoutubePlayerIframeWeb() {
  WebViewPlatform.instance = WebYoutubePlayerIframePlatform();
}
