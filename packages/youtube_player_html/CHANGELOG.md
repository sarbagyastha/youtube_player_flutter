## 0.1.3

**November 21, 2026**

- Fix a type error while the player loads or reloads; IFrame API getters that return `undefined` before the iframe connects are now handled.

## 0.1.2

**November 17, 2026**

- Improve pub score.
- Require `youtube_player_platform_interface: ^0.1.2`.

## 0.1.1

**November 16, 2026**

- Add a minimal example.

## 0.1.0

**November 16, 2026**

- Implements the element control API as a no-op: the web can't reach into the cross-origin player iframe.
- Initial preview: web implementation of youtube_player on `dart:js_interop`, Wasm compatible, with optional `credentialless` iframes for cross-origin isolated pages.
