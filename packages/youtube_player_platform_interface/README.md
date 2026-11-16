<p align="center">
<img src="https://raw.githubusercontent.com/sarbagyastha/youtube_player_flutter/main/packages/youtube_player/misc/logo_512.png" width="120" alt="youtube_player_platform_interface" />
</p>

# youtube_player_platform_interface

A common platform interface for [`youtube_player`](https://pub.dev/packages/youtube_player). It defines `YoutubePlayerPlatform`, `YoutubePlayerHost`, the player event types, and the shared player page used by the native implementations.

Implementations extend `YoutubePlayerPlatform` and register themselves with `YoutubePlayerPlatform.instance = ...`. Prefer non-breaking changes to this interface; see [the federated plugin guidance](https://flutter.dev/to/federated-plugins).
