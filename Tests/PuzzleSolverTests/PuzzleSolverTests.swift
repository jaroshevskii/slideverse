import PuzzleCore
import Testing

@testable import PuzzleSolver

@Suite struct PuzzleSolverTests {
  /// Applies the solver's move sequence to a board and asserts it reaches the solved state.
  private func assertSolves(_ board: Board, sourceLocation: SourceLocation = #_sourceLocation) {
    let moves = PuzzleSolver.solution(for: board)
    var working = board
    for index in moves {
      let moved = working.move(at: index)
      #expect(moved, "solver returned an illegal move at \(index)", sourceLocation: sourceLocation)
    }
    #expect(working.isSolved, sourceLocation: sourceLocation)
  }

  @Test func alreadySolvedReturnsNoMoves() {
    #expect(PuzzleSolver.solution(for: .solved(size: 4)).isEmpty)
  }

  @Test func solvesOneMoveAway() {
    var board = Board.solved(size: 4)
    board.move(at: 11)  // empty now at 11; tapping 15 solves it
    let moves = PuzzleSolver.solution(for: board)
    #expect(moves == [15])
  }

  @Test(arguments: [3, 4, 5])
  func solvesScrambledBoards(size: Int) {
    var rng = SeededGenerator(seed: 42)
    // Bounded-move scrambles keep the optimal depth small, mirroring real gameplay.
    let moves = size * size + 10
    for _ in 0..<20 {
      assertSolves(Board.scrambled(size: size, moves: moves, using: &rng))
    }
  }
}

struct SeededGenerator: RandomNumberGenerator {
  var state: UInt64
  init(seed: UInt64) { self.state = seed &+ 0x9E37_79B9_7F4A_7C15 }
  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}
