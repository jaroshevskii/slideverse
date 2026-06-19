<div align="center">

# Slideverse

**A modern sliding-tile puzzle for iOS — pure Swift logic, an optimal C++ solver, and a hyper-modular Composable Architecture.**

[![CI](https://github.com/jaroshevskii/slideverse/actions/workflows/ci.yml/badge.svg)](https://github.com/jaroshevskii/slideverse/actions/workflows/ci.yml)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2026%20%7C%20macOS%2026-0A84FF?logo=apple&logoColor=white)](https://developer.apple.com)
[![Architecture](https://img.shields.io/badge/Architecture-TCA-1B1B1F)](https://github.com/pointfreeco/swift-composable-architecture)
[![License](https://img.shields.io/badge/License-MIT-success)](LICENSE)

</div>

Slideverse is the classic *fifteen-puzzle*, generalized to 3×3 / 4×4 / 5×5. Originally a
C++/raylib desktop game, it was re-implemented in Swift as a **hyper-modular** SwiftUI app built
on the [Point-Free][pf] ecosystem — with the original **C++ solver** still doing the heavy
lifting where native speed actually matters.

[pf]: https://www.pointfree.co
[tca]: https://github.com/pointfreeco/swift-composable-architecture

---

## Contents

- [Features](#features)
- [Architecture](#architecture)
- [C++ interoperability](#c-interoperability)
- [Data & persistence](#data--persistence)
- [Requirements](#requirements)
- [Building & running](#building--running)
- [Testing](#testing)
- [Project layout](#project-layout)
- [Data & privacy](#data--privacy)
- [License](#license)

---

## Features

| | |
|---|---|
| 🧩 **Three board sizes** | 3×3, 4×4, and 5×5, switchable on the fly. |
| 💡 **Hint & Auto-solve** | An optimal IDA\* solver (C++) highlights the next best move, or animates the puzzle to completion (3×3 / 4×4). |
| ↩️ **Undo & Pause** | Step moves back; pause freezes the timer and blurs the board. |
| 📅 **Daily Challenge** | A date-seeded board that's identical for everyone on a given day. |
| 🏆 **Scoring, stats & streaks** | Every finished game is persisted locally; best times per size, high score, daily streak. |
| 🎖️ **Achievements** | First Win, Speedy (under 1:00), No Hints, Daily Devotee, Big Board (5×5). |
| ✨ **iOS 26 polish** | Zoom navigation transitions, `matchedGeometryEffect` sliding, `numericText` transitions, SF Symbol effects, confetti on victory. |
| ⚙️ **Settings** | Light/dark/system appearance, sound effects, haptics, and default board size — persisted with `@Shared`. |

---

## Architecture

Slideverse follows the **Point-Free Way**: pure logic in value types, side effects behind
controllable **dependency clients**, features as self-contained [TCA][tca] reducers, and a thin
app shell that composes them — the same modularization philosophy as [isowords][isowords].

[isowords]: https://github.com/pointfreeco/isowords

### Module graph

```
                         ┌─────────────┐
                         │  AppFeature  │  root: StackState navigation + theme
                         └──────┬──────┘
        ┌───────────────┬───────┼────────────┬───────────────┐
        ▼               ▼       ▼            ▼               ▼
  ┌──────────┐   ┌────────────┐ │      ┌─────────────┐ ┌──────────────┐
  │HomeFeature│   │ GameFeature │ │      │ StatsFeature│ │SettingsFeature│
  └──────────┘   └──────┬─────┘ │      └──────┬──────┘ └──────┬───────┘
                        │        │             │               │
        ┌───────────────┼────────┼─────────────┴───────┐       │
        ▼               ▼        ▼                      ▼       ▼
  ┌───────────┐  ┌──────────────┐ ┌──────────────┐ ┌────────┐ ┌──────────┐
  │ PuzzleCore│  │ PuzzleSolver │ │AudioPlayer-  │ │ Models │ │ Settings │
  │  (pure)   │  │ (C++ interop)│ │HapticsClient │ │(SQLite)│ │ (@Shared)│
  └───────────┘  └──────┬───────┘ └──────────────┘ └────────┘ └──────────┘
                        ▼
                 ┌──────────────┐
                 │CxxPuzzleSolver│  C++ IDA* solver
                 └──────────────┘
```

| Module | Responsibility |
|---|---|
| **PuzzleCore** | Pure value types & rules: `Board`, `Tile`, adjacency, inversion-count solvability, scramble, scoring. No UI, no dependencies. |
| **CxxPuzzleSolver** | C++ target — optimal IDA\* solver (Manhattan + linear-conflict heuristic). |
| **PuzzleSolver** | Swift C++-interop wrapper exposing `PuzzleSolverClient` (a controllable dependency). |
| **Models** | SQLiteData `@Table` records (`CompletedGame`, `Achievement`) + `bootstrapDatabase()` migrations. |
| **Settings** | `UserSettings` persisted via `@Shared(.userSettings)` file storage. |
| **AudioPlayerClient** / **HapticsClient** | `@DependencyClient` seams for sound and haptics. |
| **Styleguide** | Shared colors, fonts, and layout constants. |
| **GameFeature** | The game reducer + SwiftUI board: timer, moves, hint/auto-solve, undo/pause, scoring, persistence. |
| **HomeFeature** | Menu + How-to-Play. |
| **StatsFeature** / **SettingsFeature** | Stats dashboard and the grouped settings form. |
| **AppFeature** | Root reducer; owns `StackState` navigation and composes everything. |

### Dependency design

Every side effect is a small, testable client following the isowords pattern — defined with
`@DependencyClient`, registered on `DependencyValues`, with `liveValue` / `testValue` /
`previewValue` implementations:

```swift
@DependencyClient
public struct PuzzleSolverClient: Sendable {
  public var solve: @Sendable (Board) async -> [Int] = { _ in [] }
}

extension DependencyValues {
  public var puzzleSolver: PuzzleSolverClient { … }
}
```

Reducers declare what they need (`@Dependency(\.puzzleSolver)`, `\.continuousClock`,
`\.defaultDatabase`, `\.haptics`, …), so tests swap in controlled implementations with zero
global state.

### Navigation

Navigation is **state-driven**. `AppReducer` owns a `StackState<Path.State>`, where `Path` is a
`@Reducer enum` of every destination (`game`, `howToPlay`, `settings`, `stats`). The view binds
it directly:

```swift
NavigationStack(path: $store.scope(state: \.path, action: \.path)) { HomeView(…) }
  destination: { store in
    switch store.case { case let .game(store): GameView(store: store); … }
  }
```

Child features emit *intents* (`store.send(.playButtonTapped)`); the parent decides what to push.
Modal flows (e.g. the Settings reset alert) use tree-based `@Presents` + `.ifLet`. Because
navigation is just data, deep links, state restoration, and synchronous `TestStore` coverage all
come for free.

---

## C++ interoperability

The sliding-puzzle's one genuinely compute-heavy task is **optimal solving**, so that's the only
thing written in C++ — using [Swift's C++ interop][cxx].

[cxx]: https://www.swift.org/documentation/cxx-interop/

**`CxxPuzzleSolver`** exposes a C-style entry point (so no `std::` types cross the language
boundary), keeping `std::vector` internal:

```cpp
namespace slideverse {
  int solve(const int *tiles, int count, int size, int *outMoves, int maxMoves);
}
```

Inside, it runs **IDA\*** with an admissible **Manhattan-distance + linear-conflict** heuristic,
so the returned move sequence is provably optimal.

**`PuzzleSolver`** (Swift, built with `.interoperabilityMode(.Cxx)`) bridges it to a clean Swift
API behind a dependency that runs off the main actor. The C++ module is brought in with
`internal import CxxPuzzleSolver`, so **no C++ type leaks into the public Swift API**:

```swift
public static func solution(for board: Board) -> [Int] {
  let tiles = board.tiles.map { CInt($0.number ?? 0) }
  var out = [CInt](repeating: 0, count: 1024)
  let produced = tiles.withUnsafeBufferPointer { t in
    out.withUnsafeMutableBufferPointer { o in
      slideverse.solve(t.baseAddress, CInt(tiles.count), CInt(board.size), o.baseAddress, 1024)
    }
  }
  return produced > 0 ? out.prefix(Int(produced)).map(Int.init) : []
}
```

### Keeping the solver fast

IDA\* time grows with the *optimal solution depth*. Full random permutations can be ~50+ moves
deep (seconds to solve), so gameplay scrambles by a **bounded number of random moves**
(`Board.scrambled(size:moves:)`) — keeping optimal depth small and solves sub-second. The solver
also has a node budget and returns "no solution" gracefully; Hint/Auto-solve are gated to ≤4×4
(`State.canUseSolver`).

### The interop cascade (build setup)

> [!IMPORTANT]
> A clang module that `requires cplusplus` cascades up the import graph: **every** Swift target
> that transitively imports `PuzzleSolver` must also enable C++ interop. `internal import` hides
> C++ from the *API*, but not from the *build graph*.

```swift
.target(
  name: "GameFeature",
  dependencies: [/* … */ "PuzzleSolver"],
  swiftSettings: [.interoperabilityMode(.Cxx)]   // also: AppFeature + the test targets
)
// package-level: cxxLanguageStandard: .cxx2b
```

The Xcode app target imports `AppFeature`, so it sets
`OTHER_SWIFT_FLAGS = -cxx-interoperability-mode=default`.

---

## Data & persistence

Game history is stored locally with **[SQLiteData]** (type-safe SQL via `@Table`, observed with
`@FetchAll`). The schema is created with `DatabaseMigrator` + `#sql` statements in
`Models/Schema.swift`, installed at launch:

[SQLiteData]: https://github.com/pointfreeco/sqlite-data

```swift
@main struct SlideverseApp: App {
  init() { prepareDependencies { try! $0.bootstrapDatabase() } }
  …
}
```

- **`CompletedGame`** — board size, moves, seconds, score, mode, day key, timestamp.
- **`Achievement`** — unlocked achievements (unique by key).

Stats screens read reactively with `@FetchAll`; the game writes results inside a reducer effect
wrapped in `withErrorReporting`. User preferences use the **[Sharing]** library — a single
`UserSettings` value persisted to disk and shared app-wide via `@Shared(.userSettings)`.

[Sharing]: https://github.com/pointfreeco/swift-sharing

**Scoring**

```
score = max(0, boardSize² · 100  −  moves · 5  −  seconds · 2  −  (usedHint ? base/2 : 0))
```

---

## Requirements

| | |
|---|---|
| **Xcode** | 26.0+ |
| **Swift** | 6.2 (package `swift-tools-version: 6.2`) |
| **Deployment** | iOS 26 · macOS 26 (the package also builds for macOS so logic tests run on the host) |
| **C++** | C++17 (`cxxLanguageStandard: .cxx17`) via Swift/C++ interoperability |

---

## Building & running

The app and the Swift package are integrated through **`Slideverse.xcworkspace`**, which
references both the app project (`App/Slideverse.xcodeproj`) and the local package; the app target
links the `AppFeature` product. **Always open the workspace, not the project.**

```sh
# Build & test the package (logic, solver, persistence, reducers) on the Mac:
swift build
swift test

# Build the iOS app via the workspace:
xcodebuild -workspace Slideverse.xcworkspace -scheme Slideverse \
  -destination 'generic/platform=iOS Simulator' \
  -skipMacroValidation build
```

> [!NOTE]
> `-skipMacroValidation` is only needed for headless/CI builds. In the Xcode GUI you approve the
> macro plugins once and run normally.

---

## Testing

Tests live alongside each module and run fast (the solver suite scrambles by bounded moves so it
stays well under a second):

- **PuzzleCoreTests** — moves, adjacency, win detection, inversion-count solvability, scoring.
- **PuzzleSolverTests** — the solver's output, applied to a scramble, reaches the solved state (3×3 / 4×4 / 5×5).
- **ModelsTests** — migrations create the schema; inserts round-trip.
- **GameFeatureTests** — `TestStore` coverage for undo, pause cancelling the timer, hint, and a winning move persisting a game + unlocking achievements.

---

## Project layout

```
slideverse/
├── Package.swift            # modules, dependencies, C++ interop settings
├── Sources/
│   ├── PuzzleCore/          # pure rules, scramble, scoring
│   ├── CxxPuzzleSolver/     # C++ IDA* solver (include/ + solver.cpp)
│   ├── PuzzleSolver/        # Swift C++ wrapper + PuzzleSolverClient
│   ├── Models/              # SQLiteData tables + migrations
│   ├── Settings/            # @Shared user settings
│   ├── AudioPlayerClient/   # sound effects dependency
│   ├── HapticsClient/       # haptics dependency
│   ├── Styleguide/          # colors, fonts, layout
│   ├── GameFeature/         # the game reducer + board view
│   ├── HomeFeature/         # menu + how-to-play
│   ├── StatsFeature/        # stats dashboard
│   ├── SettingsFeature/     # settings form
│   └── AppFeature/          # root navigation
├── Tests/                   # one suite per module
├── App/Slideverse.xcodeproj # iOS app target (thin shell)
└── Slideverse.xcworkspace   # open this — wraps the project + local package
```

---

## Data & privacy

All player data is **on-device only** — there is no network layer and nothing leaves the phone.

- **What's stored:** finished games and unlocked achievements in a SQLite database
  (`completedGames`, `achievements`), plus user preferences in `userSettings.json`.
- **Where:** the app's **Application Support** directory — not `Documents`, so it isn't exposed
  through the Files app or device file sharing.
- **At rest:** iOS applies `NSFileProtectionCompleteUntilFirstUserAuthentication` to app files by
  default, so the database is encrypted while the device is locked yet still writable in the
  background. A stricter class (`.complete`) is intentionally **not** used — it would break writes
  that land while the screen is locked.
- **Backup:** progress is included in the standard iCloud/iTunes backup (players expect their
  stats to restore on a new device); it is deliberately **not** marked `isExcludedFromBackup`.
- **Integrity:** every runtime database read/write goes through `withErrorReporting`, so a failure
  surfaces as a visible issue in development without crashing players in production.

---

## License

Slideverse is available under the MIT license. See [LICENSE](LICENSE) for details.

Built with the open-source libraries from [Point-Free](https://www.pointfree.co) — consider
supporting their work.
