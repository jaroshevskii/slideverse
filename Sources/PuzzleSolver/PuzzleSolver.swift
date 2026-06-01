internal import CxxPuzzleSolver
import PuzzleCore

/// A thin Swift facade over the C++ IDA* solver.
public enum PuzzleSolver {
  /// The optimal sequence of tile indices to tap to solve `board`.
  ///
  /// Returns an empty array if the board is already solved, or if the search exceeded
  /// its budget (e.g. a very deep 5×5 scramble).
  public static func solution(for board: Board) -> [Int] {
    let tiles = board.tiles.map { CInt($0.number ?? 0) }
    let maxMoves: CInt = 1024  // optimal solutions for our board sizes stay far below this
    var out = [CInt](repeating: 0, count: Int(maxMoves))

    let produced = tiles.withUnsafeBufferPointer { tilesPtr in
      out.withUnsafeMutableBufferPointer { outPtr in
        slideverse.solve(
          tilesPtr.baseAddress,
          CInt(tiles.count),
          CInt(board.size),
          outPtr.baseAddress,
          maxMoves
        )
      }
    }

    guard produced > 0 else { return [] }
    return out.prefix(Int(produced)).map(Int.init)
  }
}
