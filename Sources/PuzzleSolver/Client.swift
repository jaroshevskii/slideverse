import DependenciesMacros
import PuzzleCore

/// A controllable seam for solving the puzzle (powers Hint and Auto-solve).
@DependencyClient
public struct PuzzleSolverClient: Sendable {
  /// The sequence of tile indices to tap to solve the board, computed off the main actor.
  public var solve: @Sendable (Board) async -> [Int] = { _ in [] }
}
