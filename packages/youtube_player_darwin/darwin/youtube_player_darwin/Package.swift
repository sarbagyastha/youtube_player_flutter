// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "youtube_player_darwin",
  platforms: [
    .iOS("15.0"),
    .macOS("12.0"),
  ],
  products: [
    .library(name: "youtube-player-darwin", targets: ["youtube_player_darwin"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "youtube_player_darwin",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ],
      resources: [
        .process("PrivacyInfo.xcprivacy")
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
