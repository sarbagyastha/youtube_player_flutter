## 5.0.0
**BREAKING CHANGES**
* Everything is modular now. See the docs for details.
* Automatically switches to landscape on fullscreen mode.
* Added proper display of errors and detects internet connection status.
* Workarounds for iOS.
* `webview_flutter` is swapped with `ytview`. If you've been using `WebView` widget, then consider changing import paths to ytview instead.

## 4.1.0
* **Feature Added** Button to change playback rate in player.
* Added `setPlaybackRate` method to `YoutubePlayerController`. [Issue #48](https://github.com/sarbagyastha/youtube_player_flutter/issues/48) 
* **Improvement** Playback behaviour synced with `AppLifeCycle` [Issue #41](https://github.com/sarbagyastha/youtube_player_flutter/issues/41) 

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
* **FIXED** Video stuck at unknown state [Issue #24](https://github.com/sarbagyastha/youtube_player_flutter/issues/24).
* Added `hideThumbnail` and `disableDragSeek` flags. [#27](https://github.com/sarbagyastha/youtube_player_flutter/issues/27), [#29](https://github.com/sarbagyastha/youtube_player_flutter/issues/29).
* **FIXED** Fullscreen toggle in iOS.
* Minor UI improvements here and there.


## 2.0.0
* **FIXED** iOS playback is fully functional. [Issue #2](https://github.com/sarbagyastha/youtube_player_flutter/issues/2)
* Added `forceHideAnnotation` property which hides the default YouTube annotation. [Read Issue #17 for detail](https://github.com/sarbagyastha/youtube_player_flutter/issues/14)
* Added option to `mute` player.

## 1.2.0
* Added `actions` property, which can be used to add menus in top bar of video. See example for details.
* Added option to hide fullscreen button. 
* **FIXED** Current position always showing 00:00 [Issue #17](https://github.com/sarbagyastha/youtube_player_flutter/issues/17)

## 1.1.1+1
* Updated dart constraint to `>=2.2.0 <3.0.0`*. 
* **FIXED** Parsing Exceptions.

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
* **FIXED** Error while building for iOS.

## 1.0.0+2
* **FIXED** Video pausing on tapped, when controls were hidden.

## 1.0.0+1
* Added Download APK badge.

## 1.0.0
* Initial Release.
* Includes Dart Documentation.
* Includes support for Live Videos.
* Includes fast forward and rewind feature.
