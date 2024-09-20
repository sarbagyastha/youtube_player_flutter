## 9.0.4
* Fixes related to fullscreen toggle.

## 9.0.3
* Fixes issue where loading indicator would always show.
* Updates the default color of the progress indicator to be primary container color.

## 9.0.2
* Fixes issue with getting error logs even after disposing player.

## 9.0.1
* Fixes issue with fullscreen pop.

## 9.0.0
* Bumps `flutter_inappwebview` to latest version.

## 8.1.2
* Bumps `flutter_inappwebview` to latest version.
* Adds support for extracting video id from YouTube Shorts & Music URL.

## 8.1.1
* Bumps `flutter_inappwebview` to latest version.
* Fixed cast error in YouTube error.

## 8.1.0
* Upgraded minimum flutter version to `3.0.0`
* Upgraded example app

## 8.0.0
* Null Safety Release
* Added `useHybridComposition` flag

## 7.0.0+7
* Updated dependencies

## 7.0.0+6
* **(Improvements)** Added support for `endAt` in load and cue methods as well as `startAt` and `endAt` in video initialization.
* **(Fixed)** Sticky video watermarks in iOS. Fixes[#208](https://github.com/sarbagyastha/youtube_player_flutter/issues/208)
* **(Fixed)** Timing and Sizing Issue [#249](https://github.com/sarbagyastha/youtube_player_flutter/pull/249)

## 7.0.0+5
* Revert padding on fullscreen.

## 7.0.0+4
* Updated dependencies. Fixes [#262](https://github.com/sarbagyastha/youtube_player_flutter/issues/262)
* Added clear error description for 101, 105 and 150 error codes.

## 7.0.0+3
* Fixed `onExitFullScreen` callback.

## 7.0.0+2
* Added `onEnterFullScreen` & `onExitFullScreen` callback to `YoutubePlayerBuilder`.
* Player switches back to normal mode on system back, if on fullscreen.
* Added `thumbnail` parameter to `YoutubePlayer`, removed `thumbnailUrl`. Now any widget can be used as thumbnail.
* Fixed issues with progress colors.

## 7.0.0+1
* **(Fixed)** random crashes
* **(Fixed)** issues with orientation
* **(Improvements)** Added automatic fullscreen toggle wrt to orientation change
* Added [`YoutubePlayerBuilder`](https://pub.dev/documentation/youtube_player_flutter/latest/youtube_player_flutter/YoutubePlayerBuilder-class.html)
* **(Fixed)** progress color being ignored [#221](https://github.com/sarbagyastha/youtube_player_flutter/pull/221)

**BREAKING CHANGE**
* Requires **iOS**: `--ios-language swift`, Xcode version `>= 11`
* Requires **Android**: `minSdkVersion 17`
* Removed exported `WebView` widget

## 6.1.1
* Removed `forceHideAnnotation`.

## 6.1.0+7
* Updated *webview_media* constraint to `>=0.1.2<1.0.0`

## 6.1.0+6
* Exports `Webview`

## 6.1.0+5
* **(Fixed)** Infinite buffer indicator when `autoplay` set to false

## 6.1.0+2
* **(Fixed)** Some videos not playing [Issue #119](https://github.com/sarbagyastha/youtube_player_flutter/issues/119)
* **(Improvements)** Faster initial video loading time
* Added `forceHD` flag
* Shows buffer indicator until video is playable

**BREAKING CHANGE**
If you're using `webview_flutter` alongside, then remove it from dependencies. The package exports webview on its own.

## 6.0.3+2
* **(New Feature)** Pinch in/out on the player to fit video.
* **(Improvements)** Video plays in high definition, if supported.

## 6.0.3+1
* Moved `videoId`, `title`, `author` and `duration` to separate **YoutubeMetaData** class.
* **(Fixed)** Issue with invalid video id being shown while switching to fullscreen. [Issue #118](https://github.com/sarbagyastha/youtube_player_flutter/issues/118)

## 6.0.2
* Added `onEnded` callback for `YoutubePlayer` widget. (Fixes [#108](https://github.com/sarbagyastha/youtube_player_flutter/issues/108))
* Removed `isEvaluationReady` & `isLoaded` flags as it had no use anyway.
* Added `controlsVisibleAtStart` flag. (Fixes [#113](https://github.com/sarbagyastha/youtube_player_flutter/issues/113))

## 6.0.1
* **(New Feature)** Added `title` and `author` property to `YoutubePlayerController`.
* Removed **DataConnectionChecker** dependency.
* Removed `start` and `end` from flags as it wasn't functioning anyway.
* **(Improvement)** Implemented effective dart lints.
* **(Improvement)** Changed thumbnails to fetch webp format.
* **(Fixed)** Issue with Live UI [Issue #115](https://github.com/sarbagyastha/youtube_player_flutter/issues/115).

## 6.0.0
* **(Improvement)** Smooth fullscreen toggle and crash fix. [Issue #46](https://github.com/sarbagyastha/youtube_player_flutter/issues/46) & [Issue #105](https://github.com/sarbagyastha/youtube_player_flutter/issues/105)
* **(Fixed)** [Issue #93](https://github.com/sarbagyastha/youtube_player_flutter/issues/93).
* **(Fixed)** `PlayerState.ended` being call multiple times. [Issue #108](https://github.com/sarbagyastha/youtube_player_flutter/issues/108)
* **(Improvement)** Exposed `controller` parameter to all widgets. [Issue #109](https://github.com/sarbagyastha/youtube_player_flutter/issues/109). This comes handy when the widgets are to used outside the context of `YoutubePlayer` widget.
* **(Improvement)** UI and performance optimizations.

**BREAKING CHANGES**

* From now on, `YoutubePlayerController` is to be passed to the player explicitly. *(See the updated readme)*
* Removed `context` and `videoId` properties from `YoutubePlayer`.
* `flags` property is moved to `YoutubePlayerController` from `YoutubePlayer`. 
Since flags were only needed for the first time when player initializes.
* `showVideoProgressIndicator` property moved to `YoutubePlayer`.

5.2.0+1
* **(Fixed)** aspect ratio in fullscreen mode.
* **(Fixed)** sometimes showing up buffering indicator instead of error.

## 5.2.0
**BREAKING CHANGES**
* Renamed `videoId` property in YoutubePlayer to `initialVideoId`. 
* From now on changing video id must be done using either [load()](https://pub.dev/documentation/youtube_player_flutter/latest/youtube_player_flutter/YoutubePlayerController/load.html) or [cue()](https://pub.dev/documentation/youtube_player_flutter/latest/youtube_player_flutter/YoutubePlayerController/cue.html).
* **(Fixed)** Video playing sound only, on videoId change. [Issue #99](https://github.com/sarbagyastha/youtube_player_flutter/issues/99)
* **(Improvement)** Minor optimizations.
* Example updated with video list.
* Added `PlayerState.stopped`.
* Added `actionsPadding` property.

## 5.1.0
* Renamed `TotalDuration` widget to `RemainingDuration`.
* Renamed `PlayButton` widget to `PlayPauseButton`.
* **(Improvement)** Better handling of invalid video id.
* **(Improvement)** Better video orientation handling.
* **(Improvement)** Better play/pause handling w/r/t app lifecycle.
* **(Fixed)** Video pausing after jumping to certain position using progress bar.
* **BREAKING** Switched back to `webview_flutter`.
* Updated dart docs.

## 5.0.0+1
**BREAKING CHANGES**
* Everything is modular now. See the docs for details.
* Automatically switches to landscape on fullscreen mode.
* Added proper display of errors and detects internet connection status.
* Workarounds for iOS.
* `webview_flutter` is swapped with `ytview`. If you've been using `WebView` widget, then consider changing import paths to ytview instead.
* Added flags to enable/disable caption and looping.
* Added flags to change caption language, start and end time of video.

## 4.1.0
* **Feature Added** Button to change playback rate in player.
* Added `setPlaybackRate` method to `YoutubePlayerController`. [Issue #48](https://github.com/sarbagyastha/youtube_player_flutter/issues/48) 
* **(Improvement)** Playback behaviour synced with `AppLifeCycle` [Issue #41](https://github.com/sarbagyastha/youtube_player_flutter/issues/41) 

## 4.0.0+2
* Fix error reports in LiveUI. [PR#44](https://github.com/sarbagyastha/youtube_player_flutter/pull/44)
* Added `startAt` property.

## 4.0.0+1
**BREAKING CHANGES** 
* `YoutubePLayerScaffold` has been removed.
* Improved Orientations
* Uses `webview_flutter` instead of `ytview`


## 3.0.0
* **BREAKING CHANGES** See Migrating to 3.x.x for detail.
* Faster fullscreen toggling. 
* Toggles fullscreen on orientation change. [Issue #3](https://github.com/sarbagyastha/youtube_player_flutter/issues/3).
* Option to add own custom thumbnail.
* **(Fixed)** Video stuck at unknown state [Issue #24](https://github.com/sarbagyastha/youtube_player_flutter/issues/24).
* Added `hideThumbnail` and `disableDragSeek` flags. [#27](https://github.com/sarbagyastha/youtube_player_flutter/issues/27), [#29](https://github.com/sarbagyastha/youtube_player_flutter/issues/29).
* **(Fixed)** Fullscreen toggle in iOS.
* Minor UI improvements here and there.


## 2.0.0
* **(Fixed)** iOS playback is fully functional. [Issue #2](https://github.com/sarbagyastha/youtube_player_flutter/issues/2)
* Added `forceHideAnnotation` property which hides the default YouTube annotation. [Read Issue #17 for detail](https://github.com/sarbagyastha/youtube_player_flutter/issues/14)
* Added option to `mute` player.

## 1.2.0
* Added `actions` property, which can be used to add menus in top bar of video. See example for details.
* Added option to hide fullscreen button. 
* **(Fixed)** Current position always showing 00:00 [Issue #17](https://github.com/sarbagyastha/youtube_player_flutter/issues/17)

## 1.1.1+1
* Updated dart constraint to `>=2.2.0 <3.0.0`*. 
* **(Fixed)** Parsing Exceptions.

## 1.1.1
* Fix for issue
  [#12](https://github.com/sarbagyastha/youtube_player_flutter/issues/12).
* WebView is now exported alongside YoutubePlayer.

## 1.1.0
* Minor Improvements.
* Built and tested on iOS device.
* Migrated to AndroidX.
* Removed warnings on iOS builds.

## 1.0.1+1
* Added Travis CI.

## 1.0.1
* **(Fixed)** Error while building for iOS.

## 1.0.0+2
* **(Fixed)** Video pausing on tapped, when controls were hidden.

## 1.0.0+1
* Added Download APK badge.

## 1.0.0
* Initial Release.
* Includes Dart Documentation.
* Includes support for Live Videos.
* Includes fast forward and rewind feature.
