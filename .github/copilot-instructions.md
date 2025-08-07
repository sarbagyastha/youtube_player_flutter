# YouTube Player Flutter

YouTube Player Flutter is a Flutter monorepo containing three packages for YouTube video playback across multiple platforms. The packages provide seamless inline YouTube video playback using official APIs with extensive customization options.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively
- Bootstrap, build, and test the repository:
  - `curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz --output /tmp/flutter.tar.xz`
  - `cd /tmp && tar -xf flutter.tar.xz`
  - `export PATH="/tmp/flutter/bin:$PATH"`
  - `flutter --version` (should show Flutter 3.24.5)
  - `dart pub global activate melos`
  - `export PATH="$PATH:$HOME/.pub-cache/bin"`
  - `cd [repo-root] && melos bootstrap` -- takes 15-30 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
- `melos exec -- flutter analyze` -- takes 35 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
- Build examples for web:
  - `cd packages/youtube_player_iframe/example && flutter build web` -- takes 35 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
  - `cd packages/youtube_player_flutter/example && flutter build web` -- takes 35 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
- Run web examples locally:
  - `cd packages/youtube_player_iframe/example/build/web && python3 -m http.server 8080`
  - `cd packages/youtube_player_flutter/example/build/web && python3 -m http.server 8081`

## Validation
- Always manually validate any new code by building the web examples when changing core package code.
- ALWAYS run through at least one complete end-to-end scenario after making changes by building and serving the example apps.
- You can build and run the web version of the applications, and they can be tested in a browser environment.
- Always run `melos exec -- flutter analyze` before you are done or the CI will report linting issues.
- Tests currently have issues but builds and examples work correctly. Do not rely on `flutter test` for validation.

## Package Structure
The repository contains 3 main packages in the `packages/` directory:

### youtube_player_iframe (Primary package)
- **Location**: `packages/youtube_player_iframe/`
- **Purpose**: Flutter plugin for YouTube video playback using the official iFrame Player API
- **Dependencies**: `webview_flutter`, `youtube_player_iframe_web`
- **Platforms**: Android, iOS, macOS, Web
- **Example**: `packages/youtube_player_iframe/example/`
- **Key Files**:
  - `lib/src/controller/` - Player controller logic
  - `lib/src/enums/` - Player state enums
  - `lib/src/helpers/` - Utility functions
  - `lib/src/iframe_api/` - iFrame API integration
  - `assets/player.html` - HTML player template

### youtube_player_flutter (Legacy package)
- **Location**: `packages/youtube_player_flutter/`
- **Purpose**: Flutter plugin using `flutter_inappwebview` for YouTube playback
- **Dependencies**: `flutter_inappwebview`
- **Platforms**: Android, iOS
- **Example**: `packages/youtube_player_flutter/example/`
- **Tests**: `test/youtube_player_flutter_test.dart`

### youtube_player_iframe_web (Web implementation)
- **Location**: `packages/youtube_player_iframe_web/`
- **Purpose**: Web-specific implementation for `youtube_player_iframe`
- **Dependencies**: `webview_flutter_platform_interface`, `web`
- **Platform**: Web only
- **Example**: `packages/youtube_player_iframe_web/example/`

## Common Tasks

### Repository Structure
```
.
├── README.md
├── melos.yaml
├── pubspec.yaml
├── analysis_options.yaml
├── packages/
│   ├── youtube_player_iframe/
│   │   ├── lib/
│   │   ├── example/
│   │   ├── assets/
│   │   └── pubspec.yaml
│   ├── youtube_player_flutter/
│   │   ├── lib/
│   │   ├── test/
│   │   ├── example/
│   │   └── pubspec.yaml
│   └── youtube_player_iframe_web/
│       ├── lib/
│       ├── example/
│       └── pubspec.yaml
└── .github/
    └── workflows/
        └── web-deploy.yml
```

### Key Dependencies
- Flutter SDK: 3.24.0+
- Dart SDK: 3.5.0+
- Melos: 3.4.0+ (for monorepo management)
- Main dependencies: `webview_flutter`, `flutter_inappwebview`, `url_launcher`

### Build Times and Timeouts
- **Flutter SDK Installation**: 30-60 seconds
- **Melos Bootstrap**: 15-30 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
- **Flutter Analyze**: 35 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
- **Web Build (single example)**: 35 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
- **Test Suite**: 15 seconds (currently failing - use builds for validation instead)

### Working with Examples
The repository includes three example applications:

#### youtube_player_iframe/example (Recommended)
- **Purpose**: Demonstrates the main iFrame-based player with full features
- **Build**: `cd packages/youtube_player_iframe/example && flutter build web`
- **Features**: GoRouter navigation, multiple video examples, custom controls
- **Main entry**: `lib/main.dart`

#### youtube_player_flutter/example (Legacy)
- **Purpose**: Shows the legacy inappwebview-based implementation
- **Build**: `cd packages/youtube_player_flutter/example && flutter build web`
- **Use case**: For platforms not supporting webview_flutter

#### youtube_player_iframe_web/example (Web-specific)
- **Purpose**: Web-only implementation testing
- **Build**: `cd packages/youtube_player_iframe_web/example && flutter build web`

### Making Changes
When modifying package code:

1. **Always check dependencies first**: Run `melos bootstrap` if pubspec.yaml files change
2. **Primary focus on youtube_player_iframe**: This is the main package
3. **Test changes with examples**: Build and run the relevant example app
4. **Cross-package changes**: If modifying `youtube_player_iframe_web`, also test `youtube_player_iframe` examples
5. **Platform-specific changes**: Test both web and mobile-targeted code paths

### CI/CD Pipeline
- **GitHub Actions**: `.github/workflows/web-deploy.yml`
- **Deployment**: Automatically deploys `youtube_player_iframe/example` to GitHub Pages on push to main
- **Build target**: Web with WASM compilation (`--wasm` flag)
- **Base href**: Root path (`/`)

### Troubleshooting
- **Melos command not found**: Ensure `$HOME/.pub-cache/bin` is in PATH
- **Flutter command not found**: Ensure Flutter SDK is installed and in PATH
- **Build failures**: Check that all packages have been bootstrapped with `melos bootstrap`
- **Network issues in examples**: The YouTube player requires internet access to load videos
- **Test failures**: Current test suite has issues - rely on building and running examples for validation
- **Web build warnings**: Font and service worker warnings are expected and don't affect functionality

### Development Workflow
1. Install Flutter SDK and Melos as shown in "Working Effectively"
2. Bootstrap the workspace: `melos bootstrap`
3. Make your changes to the relevant package
4. Analyze code: `melos exec -- flutter analyze`
5. Build relevant examples to test: `flutter build web`
6. Serve and manually test the built examples
7. Always validate that examples run without errors before completing work