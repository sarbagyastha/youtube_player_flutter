## 0.1.0

**November 16, 2026**

- `PlayerElement`, `buildFrameScript` and `YoutubePlayerHost.setHiddenElements` / `resolveClick` / `supportsElementControl` for hiding YouTube's player UI elements and intercepting clicks on them.
- `YoutubePlayerHost.navigations` emits `NavigationRequest`s that say which element was clicked.
- Initial preview: `YoutubePlayerPlatform`, `YoutubePlayerHost`, the IFrame API protocol and the shared player page.
- The player page preconnects to YouTube, ticks on a timer, drops unchanged ticks, and derives the client identity from its own origin when none is given.
