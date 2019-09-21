class YoutubePlayerFlags {
  /// if set to true, hides the controls.
  ///
  /// Default = false
  final bool hideControls;

  /// Define whether to auto play the video after initialization or not.
  ///
  /// Default = true
  final bool autoPlay;

  /// Mutes the player initially
  ///
  /// Default = false
  final bool mute;

  /// Defines whether to show or hide progress indicator below the player.
  ///
  /// Default = false
  final bool showVideoProgressIndicator;

  /// if true, Live Playback controls will be shown instead of default one.
  ///
  /// Default = false
  final bool isLive;

  /// Hides the fullscreen button.
  ///
  /// Default = false
  final bool hideFullScreenButton;

  /// If true, hides the YouTube player annotation. Default = false
  ///
  /// Forcing annotation to hide is a hacky way. Although this shouldn't be against Youtube TOS, the author doesn't guarantee
  /// and won't be responsible for any casualties regarding the YouTube TOS violation.
  ///
  /// It's hidden by default on iOS. Changing this flag will have no effect on iOS.
  final bool forceHideAnnotation;

  /// Hides thumbnail if true
  ///
  /// Default = false
  final bool hideThumbnail;

  /// Disables seeking video position when dragging horizontally.
  ///
  /// Default = false
  final bool disableDragSeek;

  const YoutubePlayerFlags({
    this.hideControls = false,
    this.autoPlay = true,
    this.mute = false,
    this.showVideoProgressIndicator = true,
    this.isLive = false,
    this.hideFullScreenButton = false,
    this.forceHideAnnotation = true,
    this.hideThumbnail = false,
    this.disableDragSeek = false,
  });
}
