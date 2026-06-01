extension Board {
  /// Counts pairs `(i, j)` with `i < j` where the tile value at `i` is greater than at `j`.
  static func inversionCount(_ values: [Int]) -> Int {
    var inversions = 0
    for index in values.indices {
      for nested in (index + 1)..<values.count where values[index] > values[nested] {
        inversions += 1
      }
    }
    return inversions
  }

  /// Whether this arrangement of tiles can be slid back to the solved state.
  ///
  /// Uses the standard inversion-count parity rule, generalized for both odd- and
  /// even-width boards (the empty space's row from the bottom matters when the width
  /// is even).
  public var isSolvable: Bool {
    var values: [Int] = []
    values.reserveCapacity(tiles.count - 1)
    var emptyRowFromBottom = 0
    for (index, tile) in tiles.enumerated() {
      switch tile {
      case .empty: emptyRowFromBottom = size - (index / size)
      case .number(let number): values.append(number)
      }
    }

    let inversions = Self.inversionCount(values)
    if size % 2 == 1 {
      return inversions % 2 == 0
    }
    if emptyRowFromBottom % 2 == 0 {
      return inversions % 2 == 1
    }
    return inversions % 2 == 0
  }

  /// Returns a randomly shuffled board that is guaranteed solvable and not already solved.
  public static func shuffled(
    size: Int,
    using generator: inout some RandomNumberGenerator
  ) -> Board {
    var board = solved(size: size)
    repeat {
      board.tiles.shuffle(using: &generator)
    } while !board.isSolvable || board.isSolved
    return board
  }
}
