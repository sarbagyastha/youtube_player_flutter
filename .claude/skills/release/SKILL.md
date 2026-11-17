---
name: release
description: Release a package to pub.dev. Bumps the version, writes the changelog, commits, then asks before creating and pushing the release tag that triggers CI publishing.
argument-hint: <package> [patch|minor|major]
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh run *) Bash(dart pub global *) Bash(flutter analyze*) Read Edit
---
Release `$ARGUMENTS` (package name under `packages/`, optional bump type). Stop and ask at every ✋.

Packages, tag prefixes and release order (earlier rows are depended on by later ones in the same chain):

| Chain | Package | Tag prefix | Constraint keys to bump in dependents |
|---|---|---|---|
| old | `youtube_player_iframe_web` | `yp_iframe_web` | `youtube_player_iframe_web` in `youtube_player_iframe` |
| old | `youtube_player_iframe` | `yp_iframe` | none |
| new | `youtube_player_platform_interface` | `yp_pi` | `youtube_player_platform_interface` in android, darwin, html, `youtube_player` |
| new | `youtube_player_android` / `youtube_player_darwin` / `youtube_player_html` | `yp_android` / `yp_darwin` / `yp_html` | same-named key in `youtube_player` |
| new | `youtube_player` | `yp` | `youtube_player` in `youtube_player_flutter` |
| new | `youtube_player_flutter` | `yp_flutter` | none |

`youtube_player_windows` (`yp_windows`) and `youtube_player_linux` (`yp_linux`) are not created yet; when added, put them in the android/darwin/html tier and add them to the root `pubspec.yaml` `workspace:` and `melos.categories.publishable` lists.

1. **Preconditions**: working tree clean and on `develop` or `main`; run `git pull`. If not, stop and ask. If no package given, ask which one from the table.
2. **Changes**: find the last tag `git describe --tags --match '<prefix>-v*' --abbrev=0` (prefix from the table); fall back to the old full-name tag, then to the commit that last touched the pubspec version. Review `git log <tag>..HEAD -- packages/<package>`. A package with no tag yet is a first release: use its current pubspec version as is.
3. **Bump type** ✋: if not given, propose patch/minor/major from the changes and confirm.
4. **Version**: update `version:` in `packages/<package>/pubspec.yaml`.
5. **Order**: release in the table's order. Before releasing `<package>`, check each package earlier in its chain for a pending release (commits since its last tag touching `packages/<pkg>`, or pubspec version differing from its latest tag). If any is pending, release it first (full flow, tag pushed) before continuing. After releasing, update the dependents' constraints listed in the table's last column and release each later package that has pending changes or a constraint bump, one at a time in order. Before starting the next package, wait for the previous tag's publish run to succeed (`gh run list --workflow publish.yml --limit 1`, `gh run watch`), since dependents resolve it from pub.dev.
6. **Changelog** ✋: prepend an entry to `packages/<package>/CHANGELOG.md` using the existing format and today's date; user-facing changes only, one line each. Show it and wait for approval.
7. **Verify**: `flutter analyze` in `packages/<package>`, then pana for that package only (not melos): `dart pub global activate pana` and `dart pub global run pana --exit-code-threshold 0 packages/<package>`. Stop on failures.
8. **Commit**: commit the bump (e.g. `bump <package> to <version>`).
9. **Tag** ✋: ask whether to create the local tag `<prefix>-v<version>`. Create it only on yes.
10. **Push** ✋: separately ask before `git push` and `git push origin <prefix>-v<version>`. Pushing the tag triggers `.github/workflows/publish.yml`. CI does not run pana, so step 7 is the readiness gate. Never run `pub publish` yourself.
