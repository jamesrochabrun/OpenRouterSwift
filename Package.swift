// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "OpenRouterSwift",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "OpenRouterSwift", targets: ["OpenRouterSwift"]),
  ],
  dependencies: [
    // TODO: switch to .package(url: "https://github.com/jamesrochabrun/SwiftOpenAI", from: "4.5.0")
    // once a release containing the public HTTPRequest/HTTPResponse fields and PATCH/PUT
    // HTTPMethod cases is tagged.
    .package(path: "../SwiftOpenAI"),
    // S256 PKCE on Linux (Apple platforms use CryptoKit).
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
  ],
  targets: [
    .target(
      name: "OpenRouterSwift",
      dependencies: [
        .product(name: "SwiftOpenAI", package: "SwiftOpenAI"),
        .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux])),
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
      ]),
    .testTarget(
      name: "OpenRouterSwiftTests",
      dependencies: ["OpenRouterSwift"]),
  ])
