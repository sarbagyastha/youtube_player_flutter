---
name: release
description: Release a package to pub.dev. Bumps the version, writes the changelog, commits, then asks before creating and pushing the release tag that triggers CI publishing.
argument-hint: <package> [patch|minor|major]
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(dart run melos run pana) Bash(flutter analyze*) Read Edit
---
Release `$ARGUMENTS` (package name under `packages/`, optional bump type). Stop and ask at every ✋.

1. **Preconditions**: working tree clean and on `develop` or `main`; run `git pull`. If not, stop and ask. If no package given, ask which of `youtube_player_iframe_web`, `youtube_player_iframe`, `youtube_player_flutter`.
2. **Changes**: find the last tag `git describe --tags --match '<prefix>-v*' --abbrev=0`, where `<prefix>` is the tag prefix from CLAUDE.md (`yp_flutter`, `yp_iframe`, `yp_iframe_web`); fall back to the old full-name tag, then to the commit that last touched the pubspec version. Review `git log <tag>..HEAD -- packages/<package>`.
3. **Bump type** ✋: if not given, propose patch/minor/major from the changes and confirm.
4. **Version**: update `version:` in `packages/<package>/pubspec.yaml`.
5. **Dependents**: if another publishable package depends on this one, update its constraint (see CLAUDE.md Gotchas) and offer to release it afterwards, in dependency order.
6. **Changelog** ✋: prepend an entry to `packages/<package>/CHANGELOG.md` using the existing format and today's date; user-facing changes only, one line each. Show it and wait for approval.
7. **Verify**: `flutter analyze` in the package and `dart run melos run pana`. Stop on failures.
8. **Commit**: commit the bump (e.g. `bump <package> to <version>`).
9. **Tag** ✋: ask whether to create the local tag `<prefix>-v<version>`. Create it only on yes.
10. **Push** ✋: separately ask before `git push` and `git push origin <prefix>-v<version>`. Pushing the tag triggers `.github/workflows/publish.yml`. Never run `pub publish` yourself.
