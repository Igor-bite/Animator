// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "IKUI",
  platforms: [
    .iOS(.v15),
  ],
  products: [
    .library(
      name: "IKUI",
      targets: ["IKUI"]
    ),
  ],
  dependencies: [
    .package(path: "./IKUtils"),
    .package(url: "https://github.com/SnapKit/SnapKit", .exactItem("5.7.1"))
  ],
  targets: [
    .target(
      name: "IKUI",
      dependencies: [
        "IKUtils",
        "SnapKit"
      ]
    ),
  ],
  swiftLanguageVersions: [
    .version("5"),
  ]
)
