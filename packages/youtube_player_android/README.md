<p align="center">
<img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player/misc/logo_512.png" width="120" alt="youtube_player_android" />
</p>

# youtube_player_android

The Android implementation of [`youtube_player`](https://pub.dev/packages/youtube_player). It hosts the YouTube IFrame Player API in a minimal `android.webkit.WebView` driven through Pigeon Native Interop (JNI, no platform channels), and uses the WebView's custom-view fullscreen.

The view uses [Hybrid Composition++](https://docs.flutter.dev/platform-integration/android/platform-views#hcpp) when the app opts in (`io.flutter.embedding.android.EnableHcpp` in `AndroidManifest.xml`) and the device supports it (API 34+, Vulkan), and Texture Layer Hybrid Composition otherwise.

## Usage

This package is [endorsed](https://flutter.dev/to/endorsed-federated-plugin): depend on `youtube_player` and this implementation is included automatically.
