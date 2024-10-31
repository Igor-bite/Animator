// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "IKDrawing",
  platforms: [
    .iOS(.v15),
  ],
  products: [
    .library(
      name: "IKDrawing",
      targets: ["IKDrawing"]
    ),
  ],
  dependencies: [
    .package(path: "./IKUtils")
  ],
  targets: [
    .target(
      name: "IKDrawing",
      dependencies: [
        "IKUtils"
      ]
    ),
  ],
  swiftLanguageVersions: [
    .version("5"),
  ]
)
