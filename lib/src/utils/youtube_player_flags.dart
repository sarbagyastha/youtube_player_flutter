/// Defines player flags for [YoutubePlayer].
class YoutubePlayerFlags {
  /// if set to true, hides the controls.
  ///
  /// Default is false.
  final bool hideControls;

  /// Define whether to auto play the video after initialization or not.
  ///
  /// Default is true.
  final bool autoPlay;

  /// Mutes the player initially
  ///
  /// Default is false.
  final bool mute;

  /// Defines whether to show or hide progress indicator below the player.
  ///
  /// Default is false.
  final bool showVideoProgressIndicator;

  /// if true, Live Playback controls will be shown instead of default one.
  ///
  /// Default is false.
  final bool isLive;

  /// If true, hides the YouTube player annotation. Default is false.
  ///
  /// Forcing annotation to hide is a hacky way. Although this shouldn't be against Youtube TOS, the author doesn't guarantee
  /// and won't be responsible for any casualties regarding the YouTube TOS violation.
  ///
  /// It's hidden by default on iOS. Changing this flag will have no effect on iOS.
  final bool forceHideAnnotation;

  /// Hides thumbnail if true.
  ///
  /// Default is false.
  final bool hideThumbnail;

  /// Disables seeking video position when dragging horizontally.
  ///
  /// Default is false.
  final bool disableDragSeek;

  /// Enabling this causes the player to play the video again and again.
  ///
  /// Default is false.
  final bool loop;

  /// Enabling causes closed captions to be shown by default.
  ///
  /// Default is true.
  final bool enableCaption;

  /// Specifies the default language that the player will use to display captions. Set the parameter's value to an [ISO 639-1 two-letter language code](http://www.loc.gov/standards/iso639-2/php/code_list.php).
  ///
  /// Default is `en`.
  final String captionLanguage;

  /// Causes the player to begin playing the video at the given number of seconds from the start of the video.
  final Duration start;

  /// Specifies the time, measured in seconds from the start of the video,
  /// when the player should stop playing the video.
  ///
  /// The time is measured from the beginning of the video.
  final Duration end;

  const YoutubePlayerFlags({
    this.hideControls = false,
    this.autoPlay = true,
    this.mute = false,
    this.showVideoProgressIndicator = true,
    this.isLive = false,
    this.forceHideAnnotation = true,
    this.hideThumbnail = false,
    this.disableDragSeek = false,
    this.enableCaption = true,
    this.captionLanguage = 'en',
    this.loop = false,
    this.start,
    this.end,
  });

  YoutubePlayerFlags copyWith({
    bool hideControls,
    bool autoPlay,
    bool mute,
    bool showVideoProgressIndicator,
    bool isLive,
    bool forceHideAnnotation,
    bool hideThumbnail,
    bool disableDragSeek,
    bool loop,
    bool enableCaption,
    String captionLanguage,
    Duration start,
    Duration end,
  }) {
    return YoutubePlayerFlags(
      autoPlay: autoPlay ?? this.autoPlay,
      captionLanguage: captionLanguage ?? this.captionLanguage,
      disableDragSeek: disableDragSeek ?? this.disableDragSeek,
      enableCaption: enableCaption ?? this.enableCaption,
      end: end ?? this.end,
      forceHideAnnotation: forceHideAnnotation ?? this.forceHideAnnotation,
      hideControls: hideControls ?? this.hideControls,
      hideThumbnail: hideThumbnail ?? this.hideThumbnail,
      isLive: isLive ?? this.isLive,
      loop: loop ?? this.loop,
      mute: mute ?? this.mute,
      showVideoProgressIndicator:
          showVideoProgressIndicator ?? this.showVideoProgressIndicator,
      start: start ?? this.start,
    );
  }
}
