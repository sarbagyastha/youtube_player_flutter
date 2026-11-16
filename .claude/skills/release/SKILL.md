---
name: release
description: Release a package to pub.dev. Bumps the version, writes the changelog, commits, then asks before creating and pushing the release tag that triggers CI publishing.
argument-hint: <package> [patch|minor|major]
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(dart pub global *) Bash(flutter analyze*) Read Edit
---
Release `$ARGUMENTS` (package name under `packages/`, optional bump type). Stop and ask at every ✋.

1. **Preconditions**: working tree clean and on `develop` or `main`; run `git pull`. If not, stop and ask. If no package given, ask which of `youtube_player_iframe_web`, `youtube_player_iframe`, `youtube_player_flutter`, or the new family `youtube_player_platform_interface`, `youtube_player_android`, `youtube_player_darwin`, `youtube_player_html`, `youtube_player`.
2. **Changes**: find the last tag `git describe --tags --match '<prefix>-v*' --abbrev=0`, where `<prefix>` is the tag prefix from CLAUDE.md (`yp_flutter`, `yp_iframe`, `yp_iframe_web`); fall back to the old full-name tag, then to the commit that last touched the pubspec version. Review `git log <tag>..HEAD -- packages/<package>`.
3. **Bump type** ✋: if not given, propose patch/minor/major from the changes and confirm.
4. **Version**: update `version:` in `packages/<package>/pubspec.yaml`.
5. **Order**: packages are always released in dependency order: `youtube_player_iframe_web` → `youtube_player_iframe` → `youtube_player_flutter`. For the new family: `youtube_player_platform_interface` → `youtube_player_android` / `youtube_player_darwin` / `youtube_player_html` → `youtube_player`. Before releasing `<package>`, check each package earlier in that chain for a pending release (commits since its last tag touching `packages/<pkg>`, or pubspec version differing from its latest tag). If any is pending, release it first (full flow, tag pushed) before continuing. After releasing, update dependents' constraints (see CLAUDE.md Gotchas) and release each later package that has pending changes or a constraint bump, one at a time in order, each tag pushed before the next package starts.
6. **Changelog** ✋: prepend an entry to `packages/<package>/CHANGELOG.md` using the existing format and today's date; user-facing changes only, one line each. Show it and wait for approval.
7. **Verify**: `flutter analyze` in `packages/<package>`, then pana for that package only (not melos): `dart pub global activate pana` and `dart pub global run pana --exit-code-threshold 0 packages/<package>`. Stop on failures.
8. **Commit**: commit the bump (e.g. `bump <package> to <version>`).
9. **Tag** ✋: ask whether to create the local tag `<prefix>-v<version>`. Create it only on yes.
10. **Push** ✋: separately ask before `git push` and `git push origin <prefix>-v<version>`. Pushing the tag triggers `.github/workflows/publish.yml`. CI does not run pana, so step 7 is the readiness gate. Never run `pub publish` yourself.
