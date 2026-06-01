/// A single cell on the sliding puzzle board: either a numbered tile or the blank space.
public enum Tile: Equatable, Hashable, Sendable {
  case number(Int)
  case empty
}

extension Tile {
  /// The number on the tile, or `nil` for the empty space.
  public var number: Int? {
    switch self {
    case .number(let number): number
    case .empty: nil
    }
  }
}
