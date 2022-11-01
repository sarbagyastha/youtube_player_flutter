import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe_web/src/youtube_player_iframe_web.dart';

/// Registers the web implementation for the youtube player.
void registerYoutubePlayerIframeWeb() {
  WebView.platform = YoutubePlayerIframeWeb();
}
