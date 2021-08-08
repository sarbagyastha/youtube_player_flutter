// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// As workaround for this issue https://updaymedia.atlassian.net/browse/ESC-768?focusedCommentId=73895
/// we need callbacks or some other implementation
class YoutubeCallbacks {
  const YoutubeCallbacks({
    this.onPlay,
    this.onPause,
    this.onEnd,
  });

  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onEnd;
}
