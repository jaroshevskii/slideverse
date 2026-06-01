/// A square sliding-puzzle board of `size × size` tiles stored in row-major order.
///
/// A solved board reads `1...(size*size - 1)` left-to-right, top-to-bottom, with the
/// empty space in the bottom-right corner. Tiles may only slide into the empty space
/// when they are orthogonally adjacent to it.
public struct Board: Equatable, Sendable {
  /// The width (and height) of the board, e.g. `4` for a classic fifteen-puzzle.
  public let size: Int

  /// The tiles in row-major order. Always contains exactly one `.empty`.
  public internal(set) var tiles: [Tile]

  public init(size: Int, tiles: [Tile]) {
    self.size = size
    self.tiles = tiles
  }

  /// The solved board for the given `size`.
  public static func solved(size: Int) -> Board {
    let count = size * size
    var tiles = (1..<count).map(Tile.number)
    tiles.append(.empty)
    return Board(size: size, tiles: tiles)
  }

  /// The index of the empty space.
  public var emptyIndex: Int {
    tiles.firstIndex(of: .empty) ?? tiles.count - 1
  }

  /// Whether every numbered tile is in its solved position and the empty space is last.
  public var isSolved: Bool {
    for index in 0..<(tiles.count - 1) where tiles[index] != .number(index + 1) {
      return false
    }
    return tiles[tiles.count - 1] == .empty
  }

  /// Whether two board indices share a row or column and are exactly one cell apart.
  public func isAdjacent(_ lhs: Int, _ rhs: Int) -> Bool {
    let (row1, col1) = (lhs / size, lhs % size)
    let (row2, col2) = (rhs / size, rhs % size)
    return (row1 == row2 && abs(col1 - col2) == 1)
      || (col1 == col2 && abs(row1 - row2) == 1)
  }

  /// Slides the tile at `index` into the empty space if it is adjacent to it.
  /// - Returns: `true` if a tile moved, `false` if the move was illegal.
  @discardableResult
  public mutating func move(at index: Int) -> Bool {
    let empty = emptyIndex
    guard tiles.indices.contains(index), isAdjacent(index, empty) else { return false }
    tiles.swapAt(index, empty)
    return true
  }
}
