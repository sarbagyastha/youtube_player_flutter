# youtube_player (melos/pub workspace)

## Commands
- Install deps: `flutter pub get` (workspace root; no separate bootstrap)
- Publish-readiness check: `dart run melos run pana`
- Analyze: `flutter analyze` inside a package dir
- Release: `/release <package> [patch|minor|major]`

## Layout
- Publishable: `packages/youtube_player_iframe_web` → `youtube_player_iframe` → `youtube_player_flutter` (arrow = depended on by).
- New federated family (built from scratch, Pigeon-driven native WebViews, no webview_flutter): `youtube_player_platform_interface` → `youtube_player_android` / `youtube_player_darwin` (iOS+macOS, shared Swift) / `youtube_player_html` (web, js_interop, Wasm) → `youtube_player` (app-facing, endorses the impls). Regenerate Pigeon with `dart run pigeon --input pigeons/messages.dart` inside an impl package.
- `*/example` dirs are workspace members, never published.

## Conventions
- Each package has its own `CHANGELOG.md`: `## <version>`, then `**Month D, YYYY**`, then `- ` bullets (newest first).
- Release tags are `<prefix>-v<version>` (e.g. `yp_iframe-v6.0.4`). Prefixes: `yp_flutter` = youtube_player_flutter, `yp_iframe` = youtube_player_iframe, `yp_iframe_web` = youtube_player_iframe_web. New family: `yp` = youtube_player, `yp_pi` = youtube_player_platform_interface, `yp_android`, `yp_darwin`, `yp_html`, `yp_windows`, `yp_linux`. Older tags used full package names.
- Publishing happens only in CI (`.github/workflows/publish.yml`) when a tag is pushed. Never run `pub publish` locally.

## Gotchas
- New-family code uses primary constructors and the latest Dart syntax everywhere (SDK ^3.14.0, Flutter >=3.50.0).
- New-family release order: platform_interface → android/darwin/html → youtube_player.
- When a package's version bumps, update dependents' constraints (`youtube_player_iframe: ^x` in flutter, `youtube_player_iframe_web: ^x` in iframe) and release them after it.
