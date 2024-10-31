// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "IKUtils",
  platforms: [
    .iOS(.v15),
  ],
  products: [
    .library(
      name: "IKUtils",
      targets: ["IKUtils"]
    ),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "IKUtils",
      dependencies: []
    ),
  ],
  swiftLanguageVersions: [
    .version("5"),
  ]
)
