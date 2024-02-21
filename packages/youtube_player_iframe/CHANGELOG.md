# Changelog
## 5.1.1
**Feb 21, 2024**
- Improves pub score.

## 5.1.0
**Feb 21, 2024**
- Bumps dependency to latest version.

## 5.0.0
**Dec 20, 2023**
- Bumps dependency to latest version.
- Adds support for wasm.
- Bumps flutter version to `>=3.18.0-0`.
- Fixes issue using `WebViewWidget` from `webview_flutter` package, together with the package.

## 4.0.4
**Jan 29, 2023**
- Fixed platform listing in pub.dev

## 4.0.3
**Jan 29, 2023**
- Endorse `youtube_player_iframe_web` as default web implementation package.

## 4.0.2
**Jan 27, 2023**
- Upgraded dependencies.
- Fixed issue with `YoutubePlayerController.close`.
- Exposed `YoutubePlayerValue`.

## 4.0.1
**Dec 26, 2022**
- Fixed video playback issue in web release.

## 4.0.0
**Dec 25, 2022**

**Breaking Change**
- Fixed video playback issues in web for some videos.
- Deprecated params in v3 has been removed.
- Deprecated `YoutubePlayerIFrame` has been removed.
- `YoutubePlayer.controller` is now required.
- `YoutubePlayerController.onInit` has been removed. As unlike before, the controller is available as soon as it's created.
- `YoutubePlayerController.getCurrentPositionStream` has been deprecated in favor of `YoutubePlayerController.videoStateStream`.
- `YoutubePlayerController.onFullscreenChange` has been deprecated in favor of `YoutubePlayerController.setFullScreenListener`.
- Added support for specifying `YoutubePlayerParams.pointerEvents`. Thanks to [@keithcwk](https://github.com/keithcwk).
- Added [FullscreenYoutubePlayer].
- Upgraded dependencies.

## 3.1.0
**Sep 15, 2022**
- Fixed issues with example app
- Fixed `strictRelatedVideos` flag working incorrectly. Thanks to [@ChisatoMatsuzaki](https://github.com/ChisatoMatsuzaki).
- Deprecated `startAt` & `endAt` from *YoutubePlayerParams*.
- Removed `volume` from *YoutubePlayerValue* as it's no longer used.

## 3.0.4
**Aug 21, 2022**

- Fixed video not loading on non-web platform when controls were disabled
- Added `YoutubePlayerController.fromVideoId`.
- Added `enableFullScreenOnVerticalDrag` property to **YoutubePlayer**.
- Fixed issue with `videoUrl` getter.
- Added video list and manual fullscreen examples.
- Added `getCurrentPositionStream` to **YoutubePlayerController**.
- Deprecated `YoutubePlayerIFrame` in favor of `YoutubePlayer`.
- Deprecated `autoPlay` param in **YoutubePlayerParams**, as it's no longer used.

## 3.0.3
**Aug 14, 2022**

- Fixed issues related to Fullscreen.
- Added `onInit` & `onFullscreenChange` callbacks to **YoutubePlayerController**.
- Added **Migrating to v3** section in the docs.
- Listed `Swipe up/down to enter/exit fullscreen mode` as a feature in the docs.
- Deprecated `autoPlay` param in **YoutubePlayerParams**, as it's no longer used.
- Removed `hasPlayed`, `position` & `buffered` from **YoutubePlayerValue**, as these values can be accessed through **YoutubePlayerController**.

## 3.0.2
**Aug 12, 2022**

- Improved pub score.

## 3.0.1
**Aug 12, 2022**

- Fixed the supported platform in pub.dev

## 3.0.0
**Aug 12, 2022**

**Breaking Change**
- Switched to `webview_flutter`.
- Better web support.
- APIs are now identical to that of Youtube Player Iframe API.
- Exposed all the supported iFrame APIs.
- Fixed issue with videos not playing on Android.
- Added support for FullScreen gestures like on Youtube Mobile App.
- Added support for YouTube Shorts URL.
- Added `YoutubePlayerScaffold` to better handle the fullscreen mode.

## 2.3.0
**May 16, 2022**

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
