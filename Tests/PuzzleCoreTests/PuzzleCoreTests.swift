import Testing

@testable import PuzzleCore

@Suite struct BoardTests {
  @Test func solvedBoardIsSolved() {
    let board = Board.solved(size: 4)
    #expect(board.isSolved)
    #expect(board.tiles.last == .empty)
    #expect(board.tiles.first == .number(1))
  }

  @Test func emptyIndexIsLastWhenSolved() {
    #expect(Board.solved(size: 4).emptyIndex == 15)
    #expect(Board.solved(size: 3).emptyIndex == 8)
  }

  @Test func adjacency() {
    let board = Board.solved(size: 4)
    #expect(board.isAdjacent(0, 1))
    #expect(board.isAdjacent(0, 4))
    #expect(!board.isAdjacent(0, 5))
    #expect(!board.isAdjacent(3, 4))  // wraps a row edge — not adjacent
  }

  @Test func legalMoveSwapsWithEmpty() {
    var board = Board.solved(size: 4)
    // Tile 12 sits at index 11, directly above the empty space at index 15.
    let moved = board.move(at: 11)
    #expect(moved)
    #expect(board.tiles[15] == .number(12))
    #expect(board.tiles[11] == .empty)
    #expect(!board.isSolved)
  }

  @Test func illegalMoveDoesNothing() {
    var board = Board.solved(size: 4)
    let moved = board.move(at: 0)  // far from the empty space
    #expect(!moved)
    #expect(board.isSolved)
  }
}

@Suite struct SolvabilityTests {
  @Test func inversionCount() {
    #expect(Board.inversionCount([1, 2, 3]) == 0)
    #expect(Board.inversionCount([3, 2, 1]) == 3)
    #expect(Board.inversionCount([2, 1, 3]) == 1)
  }

  @Test func solvedBoardIsSolvable() {
    // A single legal slide away from solved is, by construction, solvable.
    var board = Board.solved(size: 4)
    board.move(at: 11)
    #expect(board.isSolvable)
  }

  @Test(arguments: [3, 4, 5])
  func shuffledIsAlwaysSolvableAndNotSolved(size: Int) {
    var rng = SeededGenerator(seed: 0)
    for _ in 0..<200 {
      let board = Board.shuffled(size: size, using: &rng)
      #expect(board.isSolvable)
      #expect(!board.isSolved)
      #expect(board.tiles.count == size * size)
    }
  }
}

@Suite struct ScoringTests {
  @Test func higherForBiggerBoards() {
    let small = Board.score(boardSize: 3, moves: 20, seconds: 30, usedHint: false)
    let big = Board.score(boardSize: 5, moves: 20, seconds: 30, usedHint: false)
    #expect(big > small)
  }

  @Test func hintHalvesBase() {
    let withHint = Board.score(boardSize: 4, moves: 0, seconds: 0, usedHint: true)
    let withoutHint = Board.score(boardSize: 4, moves: 0, seconds: 0, usedHint: false)
    #expect(withoutHint == 1600)
    #expect(withHint == 800)
  }

  @Test func neverNegative() {
    #expect(Board.score(boardSize: 3, moves: 10_000, seconds: 10_000, usedHint: true) == 0)
  }

  @Test func scrambledStaysSolvableAndUnsolved() {
    var rng = SeededGenerator(seed: 7)
    for size in [3, 4, 5] {
      let board = Board.scrambled(size: size, moves: size * size + 10, using: &rng)
      #expect(board.isSolvable)
      #expect(!board.isSolved)
    }
  }
}

/// A deterministic generator so shuffle tests are reproducible.
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
