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
    .package(path: "./IKUtils")
  ],
  targets: [
    .target(
      name: "IKUI",
      dependencies: ["IKUtils"]
    ),
  ],
  swiftLanguageVersions: [
    .version("5"),
  ]
)
