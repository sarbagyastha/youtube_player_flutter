# youtube_player (melos/pub workspace)

## Commands
- Install deps: `flutter pub get` (workspace root; no separate bootstrap)
- Publish-readiness check: `dart run melos run pana`
- Analyze: `flutter analyze` inside a package dir
- Release: `/release <package> [patch|minor|major]`

## Layout
- Publishable: `packages/youtube_player_iframe_web` → `youtube_player_iframe` → `youtube_player_flutter` (arrow = depended on by).
- `*/example` dirs are workspace members, never published.

## Conventions
- Each package has its own `CHANGELOG.md`: `## <version>`, then `**Month D, YYYY**`, then `- ` bullets (newest first).
- Release tags are `<prefix>-v<version>` (e.g. `yp_iframe-v6.0.4`). Prefixes: `yp_flutter` = youtube_player_flutter, `yp_iframe` = youtube_player_iframe, `yp_iframe_web` = youtube_player_iframe_web. Older tags used full package names.
- Publishing happens only in CI (`.github/workflows/publish.yml`) when a tag is pushed. Never run `pub publish` locally.

## Gotchas
- When a package's version bumps, update dependents' constraints (`youtube_player_iframe: ^x` in flutter, `youtube_player_iframe_web: ^x` in iframe) and release them after it.
