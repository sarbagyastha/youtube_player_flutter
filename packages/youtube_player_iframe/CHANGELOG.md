# 3.0.4
- Fixed video not loading on non-web platform when controls were disabled
- Added `YoutubePlayerController.fromVideoId`.
- Added `enableFullScreenOnVerticalDrag` property to **YoutubePlayer**.
- Fixed issue with `videoUrl` getter.
- Added video list and manual fullscreen examples.
- Added `getCurrentPositionStream` to **YoutubePlayerController**.
- Deprecated `YoutubePlayerIFrame` in favor of `YoutubePlayer`.
- Deprecated `autoPlay` param in **YoutubePlayerParams**, as it's no longer used.

# 3.0.3
- Fixed issues related to Fullscreen.
- Added `onInit` & `onFullscreenChange` callbacks to **YoutubePlayerController**.
- Added **Migrating to v3** section in the docs.
- Listed `Swipe up/down to enter/exit fullscreen mode` as a feature in the docs.
- Deprecated `autoPlay` param in **YoutubePlayerParams**, as it's no longer used.
- Removed `hasPlayed`, `position` & `buffered` from **YoutubePlayerValue**, as these values can be accessed through **YoutubePlayerController**.

# 3.0.2
- Improved pub score.

# 3.0.1
- Fixed the supported platform in pub.dev

# 3.0.0
**Breaking Change**
- Switched to `webview_flutter`.
- Better web support.
- APIs are now identical to that of Youtube Player Iframe API.
- Exposed all the supported iFrame APIs.
- Fixed issue with videos not playing on Android.
- Added support for FullScreen gestures like on Youtube Mobile App.
- Added support for YouTube Shorts URL.
- Added `YoutubePlayerScaffold` to better handle the fullscreen mode.

# 2.3.0
- Upgraded minimum flutter version to `3.0.0`
- Upgraded example app

# 2.2.2
- Fixed inline playback issue iOS. See [#525](https://github.com/sarbagyastha/youtube_player_flutter/issues/525)
- UI update to example app

# 2.2.1
- Removed `YoutubePlayerController.setWebDebuggingInAndroid`

# 2.2.0
**Contains Breaking Changes**
- Fixed issue iOS redirection issue
- `YoutubePlayerController` is no more Stream.
- Added `YoutubePlayerController.setWebDebuggingInAndroid`
- Added `buildWhen` to **YoutubeValueBuilder**
- Fixed issue where metadata weren't updated correctly
- Fixed `desktopMode` flag.

# 2.1.0
- Updated dependencies to latest version.

# 2.0.0
- Migrated to null safety
- Added `useHybridComposition` param.
- Updated dependencies to latest version.

## 1.2.0+2
- Added `YoutubePlayerParams.privacyEnhanced` flag.
- Exposed `gestureRecognizers` through `YoutubePlayerIFrame` widget.
- Handled internal links correctly. Tapping on video suggestion will now play it and all the buttons are enabled.
- Flutter `>=1.22.0 <2.0.0` is required.

## 1.1.0
- **Fixed** Black Screen on iOS [#302](https://github.com/sarbagyastha/youtube_player_flutter/issues/302).
- **Fixed** Minor fix for web player [#300](https://github.com/sarbagyastha/youtube_player_flutter/issues/300)
- `enableKeyboard` flag is true by default for web.

## 1.0.1
- **Fixed** Disabled navigation inside the player. This solves the issue where tapping on actions would navigate to different web pages.
- Removed `foreceHD` param, in favor of `desktopMode`. The `desktopMode` also supports changing quality in fullscreen mode.
- Added two new methods, `hideTopMenu()` and `hidePauseOverlay()`. Visit ReadMe for more detail.

## 1.0.0+4
- Minor improvements

## 1.0.0+3
- Minor Fixes

## 1.0.0
- Initial Release
