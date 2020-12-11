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
