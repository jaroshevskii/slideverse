// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "slideverse",
  platforms: [
    .iOS(.v26),
    .macOS(.v26),
  ],
  products: [
    .library(name: "AppFeature", targets: ["AppFeature"]),
    .library(name: "PuzzleCore", targets: ["PuzzleCore"]),
    .library(name: "PuzzleSolverLive", targets: ["PuzzleSolverLive"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      .upToNextMinor(from: "1.26.0")),
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies", .upToNextMinor(from: "1.14.1")),
    .package(url: "https://github.com/pointfreeco/swift-navigation", .upToNextMinor(from: "2.8.0")),
    .package(url: "https://github.com/pointfreeco/swift-sharing", .upToNextMinor(from: "2.8.1")),
    .package(url: "https://github.com/pointfreeco/sqlite-data", .upToNextMinor(from: "1.6.5")),
  ],
  targets: [
    .target(name: "PuzzleCore"),
    .target(name: "Styleguide"),
    .target(name: "CxxPuzzleSolver"),
    .target(
      name: "PuzzleSolver",
      dependencies: [
        "PuzzleCore",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "PuzzleSolverLive",
      dependencies: [
        "CxxPuzzleSolver",
        "PuzzleCore",
        "PuzzleSolver",
        .product(name: "Dependencies", package: "swift-dependencies"),
      ],
      swiftSettings: [.interoperabilityMode(.Cxx)]
    ),
    .target(
      name: "Models",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "Settings",
      dependencies: [
        .product(name: "Sharing", package: "swift-sharing")
      ]
    ),
    .target(
      name: "AudioPlayerClient",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "HapticsClient",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "GameFeature",
      dependencies: [
        "AudioPlayerClient",
        "HapticsClient",
        "Models",
        "PuzzleCore",
        "PuzzleSolver",
        "Settings",
        "Styleguide",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "StatsFeature",
      dependencies: [
        "Models",
        "Styleguide",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "SettingsFeature",
      dependencies: [
        "Models",
        "Settings",
        "Styleguide",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "Sharing", package: "swift-sharing"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "HomeFeature",
      dependencies: [
        "Settings",
        "Styleguide",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "AppFeature",
      dependencies: [
        "GameFeature",
        "HomeFeature",
        "Models",
        "Settings",
        "SettingsFeature",
        "StatsFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "Sharing", package: "swift-sharing"),
      ]
    ),
    .testTarget(
      name: "PuzzleCoreTests",
      dependencies: ["PuzzleCore"]
    ),
    .testTarget(
      name: "PuzzleSolverTests",
      dependencies: ["PuzzleCore", "PuzzleSolverLive"],
      swiftSettings: [.interoperabilityMode(.Cxx)]
    ),
    .testTarget(
      name: "ModelsTests",
      dependencies: [
        "Models",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .testTarget(
      name: "GameFeatureTests",
      dependencies: [
        "AudioPlayerClient",
        "GameFeature",
        "Models",
        "PuzzleCore",
        "PuzzleSolver",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
  ],
  cxxLanguageStandard: .cxx17
)
