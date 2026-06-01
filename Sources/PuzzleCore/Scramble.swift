/// A small, deterministic SplitMix64 generator — used to make the Daily Challenge produce
/// the same board for everyone on a given day.
public struct SeededRandomNumberGenerator: RandomNumberGenerator {
  private var state: UInt64

  public init(seed: UInt64) {
    self.state = seed &+ 0x9E37_79B9_7F4A_7C15
  }

  public mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}

extension Board {
  /// Returns a board scrambled by applying `moves` random legal slides from the solved
  /// state, never immediately undoing the previous slide.
  ///
  /// Unlike ``shuffled(size:using:)`` (which permutes tiles directly), this keeps the
  /// optimal solution depth bounded by `moves`, so the IDA* solver stays fast — the right
  /// choice for generating playable, hint-able puzzles.
  public static func scrambled(
    size: Int,
    moves: Int,
    using generator: inout some RandomNumberGenerator
  ) -> Board {
    var board = solved(size: size)
    var previousEmpty = -1
    var made = 0
    while made < moves || board.isSolved {
      let empty = board.emptyIndex
      let candidates = board.tiles.indices.filter {
        $0 != previousEmpty && board.isAdjacent($0, empty)
      }
      guard let pick = candidates.randomElement(using: &generator) else { break }
      board.move(at: pick)
      previousEmpty = empty  // tapping this index next would undo the slide we just made
      made += 1
      if made > moves * 20 { break }  // safety valve for tiny boards
    }
    return board
  }
}
