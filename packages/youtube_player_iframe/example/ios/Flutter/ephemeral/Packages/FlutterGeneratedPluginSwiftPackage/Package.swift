// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "url_launcher_ios", path: "/Users/sarbagya/.pub-cache/hosted/pub.dev/url_launcher_ios-6.3.1/ios/url_launcher_ios"),
        .package(name: "webview_flutter_wkwebview", path: "/Users/sarbagya/.pub-cache/hosted/pub.dev/webview_flutter_wkwebview-3.23.0/darwin/webview_flutter_wkwebview")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview")
            ]
        )
    ]
)
