import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Signature for a builder that provides a fully custom controls UI.
///
/// - [context]: the current build context.
/// - [player]: the video surface widget. On mobile this is the placeholder
///   widget whose position matches the WebView rendered in the Overlay.
///   On non-mobile this is the actual [WebViewWidget] wrapped in an
///   [AspectRatio].
/// - [controller]: the underlying [YoutubePlayerController] for full control.
///
/// ### Example
/// ```dart
/// YoutubePlayer(
///   controller: controller,
///   builder: (context, player, ctrl) => Column(
///     children: [player, MyCustomControls(controller: ctrl)],
///   ),
/// )
/// ```
typedef YoutubePlayerBuilder = Widget Function(
  BuildContext context,
  Widget player,
  YoutubePlayerController controller,
);
