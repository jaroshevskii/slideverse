// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "slideverse",
  platforms: [
    .iOS(.v27),
    .macOS(.v27),
  ],
  products: [
    .library(name: "AppFeature", targets: ["AppFeature"]),
    .library(name: "PuzzleCore", targets: ["PuzzleCore"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMinor(from: "1.26.0")),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", .upToNextMinor(from: "1.13.0")),
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
        "CxxPuzzleSolver",
        "PuzzleCore",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
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
        .product(name: "Sharing", package: "swift-sharing"),
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
      ],
      swiftSettings: [.interoperabilityMode(.Cxx)]
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
      ],
      swiftSettings: [.interoperabilityMode(.Cxx)]
    ),
    .testTarget(
      name: "PuzzleCoreTests",
      dependencies: ["PuzzleCore"]
    ),
    .testTarget(
      name: "PuzzleSolverTests",
      dependencies: ["PuzzleCore", "PuzzleSolver"],
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
      ],
      swiftSettings: [.interoperabilityMode(.Cxx)]
    ),
  ],
  cxxLanguageStandard: .cxx2b
)
